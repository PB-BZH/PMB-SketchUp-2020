module PMB
  # ----------------------- MURS --------------------------------------
  # Cette classe est utilisée pour dessiner un mur. Elle doit afficher
  # une boîte de dialogue  et permettre de dessiner un ou plusieurs 
  # murs utilisant ces propriétés. 
  # Appuyer sur Echap pour sortir de l'outils
  # -------------------------------------------------------------------
  class Mur < Base_PMB
    attr_accessor :objets, :objets_classes, :fenetre_mur, :epure
    attr_accessor :pair, :mont_imp

    def initialize(options = {})
      defaut_options_mur = {
        'element'         	=> 'Mur',
        'nom'             	=> '',
        'dimensions'      	=> 'Standard',
        'style'           	=> 'Ext',
        'type_bloc'       	=> 'Standard',
        'justification'   	=> 'Gauche',
        'longueur'        	=> 0,
        'hauteur'         	=> 2550,
        'hauteur_linteau' 	=> 2210,
        'largeur'         	=> 190,
        'pt_debut'        	=> Geom::Point3d.new,
        'pt_fin'          	=> Geom::Point3d.new,
        'angle'           	=> 0,
        'style_angle_gauche'=> "Exterieur",
        'style_angle_droite'=> "Exterieur",
        'pt_offset'       	=> Geom::Point3d.new,
        'calque'          	=> "Construction_PMB",
        'point_angle'     	=> [],
        'montage'         	=> nil,
        'nb_angle_rang'   	=> nil,
        'noms_objet'      	=> '',
        'noms_objet_classes'=> '',
        'config_objets'   	=> [],
        'epure'           	=> []
      }
      applique_options_globales(defaut_options_mur)
      defaut_options_mur.update(options)
      super(defaut_options_mur)
      @objets = []
      @objets_classes = []
      @epure = []
      @mont_imp = nil
      if (self.nom.length == 0)
        self.nom = PMB::Base_PMB.nom_unique("mur")
      end
      change_calque_actif(self.calque,true)
    end
    
    def options_Murs(obj = self)
      proprietes_mur = [
        # prompt, attr_name, enums
        ["Justification des murs", "justification", "Gauche|Centre|Droite"],
        ["Dimensionnement","dimensions","Standard|Sur mesure"],
        ["Hauteur du mur", "hauteur", nil],
	      ["Largeur du mur", "largeur", "190|140|110|100|70"],
	      ["Type de mur", "style", "Ext|Refend"],
	      ["Style d'angle gauche", "style_angle_gauche", "Exterieur|Interieur"],
	      ["Style d'angle droite", "style_angle_droite", "Exterieur|Interieur"],
      ].freeze
      results = affiche_dialogue("Propriétés des murs", obj, proprietes_mur)
      return false if not results
      obj.hauteur = corrige_hauteur(obj.hauteur) if ((obj.hauteur.to_f % $haut_pmb)!=0)
      return results
    end
    
    def self.creation_pour_dessin(group)
      mur = Mur.new()
      mur.recupere_option_dessin(group)
      mur.noms_objet.split('|').each do |nom| 
        entite = Base_PMB.recherche_nom_entite(nom)
        next if not entite
        element = entite.get_attribute("Info élément", "element")
        case element 
          when 'Fenetre'
              fenetre = Fenetre.creation_pour_dessin(entite)
              mur.ajouter_objet(fenetre)
          when 'Porte'
              porte = Porte.creation_pour_dessin(entite)
              mur.ajouter_objet(porte)
          else
              UI.messagebox "Type inconnu: " + element + " for " + nom
          end
        end
      return mur
    end

    def chercher_groupe
      groupe = Base_PMB.recherche_nom_entite(self.nom)
      return groupe
    end
    def masquer_groupe
      groupe = Base_PMB.recherche_nom_entite(self.nom)
      groupe.hidden = true if (groupe)
    end
    
    def afficher_groupe
      groupe = Base_PMB.recherche_nom_entite(self.nom)
      groupe.hidden = false if (groupe)
    end

    def effacer_groupe
      groupe = Base_PMB.recherche_nom_entite(self.nom)
      groupe_epure = Base_PMB.recherche_nom_entite(self.nom + "_epure")
      groupe.erase! if (groupe)
      groupe_epure.erase! if(groupe_epure)
    end

    def ajouter_objet(objet, options = {})
      @objets.push(objet)
      nom = noms_objet.split('|')
      nom.push(objet.nom.to_s)
      self.noms_objet = nom.uniq.join('|')
    end
    
    def ajouter_objet_classes(objet)
      @objets_classes.push(objet)
      noms = noms_objet_classes.split('|')
      noms.push(noms_objet_classes.to_s)
      self.noms_objet_classes = noms.uniq.join('|')
    end

    def effacer_objet(nom)
      @objets.delete_if {|x| x.nom == nom }
      noms = noms_objet.split('|')
      noms.delete(nom)
      self.noms_objet = noms.uniq.join('|')
    end
    
    def effacer_objet_classes(nom)
      @objets_classes.delete_if {|x| x.nom == nom }
      noms = noms_objet.split('|')
      noms.delete(nom)
      self.noms_objet = noms.uniq.join('|')
    end
    
    def rotate(table)
      elt = table.shift()
      table.push(elt)
      return table
    end
    
    def creer_semelle(pt)
      ancien = change_calque_actif(semelle.calque,true)
      @semelle.calque        = "Fondations",
      @semelle.long_sem      = longueur,
      @semelle.justification = justification
      grp = Sketchup.active_model.active_entities.add_group(@semelle.dessine_semelle(pt))
      change_calque_actif(ancien,true)
      affiche_calque(@semelle.calque,false)
      return grp
    end
    
    def creer_bloc(pt , type = "Standard", dimensions = "Standard", ecart =0, style = self.style)
      @pmb.dimensions = dimensions
      @pmb.long_spec  = ecart
      @pmb.type_bloc  = type  
      @pmb.style = style
      grp = @pmb.pmb_bloc(pt)
      return @pmb.longueur, grp
    end
    
    def ajoute_bloc(pt , type = "Standard", angle = nil, style = "exterieur", dimensions = "Standard", ecart =0, style_bloc = self.style)
      @pmb.dimensions = dimensions
      @pmb.long_spec  = ecart
      @pmb.type_bloc  = type  
      @pmb.style = style_bloc
      if (dimensions == "Sur mesure")
        return creer_bloc(pt, type, dimensions, ecart)
      end
      case (@pmb.largeur)
      when 190
        case (@pmb.type_bloc)
        when "Standard"
          path = $PMB_190_stand_ext if (@pmb.style == "Ext")
          path = $PMB_190_stand_rfd if (@pmb.style == "Refend")
        when "Demi"
          path = $PMB_190_demi_ext if (@pmb.style == "Ext")
          path = $PMB_190_demi_ext if (@pmb.style == "Ext")
          path = $PMB_190_demi_rfd if (@pmb.style == "Refend")
        when "Angle"
        	case (self.style)
        	when "Refend"
        		path = $PMB_190_angle_rfd
        	when "Ext"
        		if (angle == "Gauche")
          		if (style == "Exterieur")
          			path = $PMB_190_angle_ext_gauche 
          		else
          			path = $PMB_190_angle_int_ext_gauche
          		end
        		elsif (angle == "Droite") 
        			if (style == "Exterieur")
        				path = $PMB_190_angle_ext_droite
        			else
        				path = $PMB_190_angle_int_ext_droite
        			end
        		end
        	end
      	else
      		puts(@pmb.type_bloc)
          UI.messagebox "Type de bloc inconnu: " + element + " for " + nom
          return nil
       	end
      when 140
        case (@pmb.type_bloc)
          when "Standard"
            path = $PMB_140_stand_ext if (@pmb.style == "Ext")
            path = $PMB_140_stand_rfd if (@pmb.style == "Refend")
          when "Demi"
            path = $PMB_140_demi_ext if (@pmb.style == "Ext")
            path = $PMB_140_demi_rfd if (@pmb.style == "Refend")
          when "Angle"
	        	case (self.style)
	        	when "Refend"
	        		path = $PMB_140_angle_rfd
	        	when "Ext"
	        		if (angle == "Gauche")
	          		if (style == "Exterieur")
	          			path = $PMB_140_angle_ext_gauche 
	          		else
	          			path = $PMB_140_angle_int_ext_gauche
	          		end
	        		elsif (angle == "Droite") 
	        			if (style == "Exterieur")
	        				path = $PMB_140_angle_ext_droite
	        			else
	        				path = $PMB_140_angle_int_ext_droite
	        			end
	        		end
	        	end
          else
              UI.messagebox "Type inconnu: " + element + " for " + nom
              return nil
           end
      when 110
        case (@pmb.type_bloc)
          when "Standard"
            path = $PMB_110_stand_ext if (@pmb.style == "Ext")
            path = $PMB_110_stand_rfd if (@pmb.style == "Refend")
          when "Demi"
            path = $PMB_110_demi_ext if (@pmb.style == "Ext")
            path = $PMB_110_demi_rfd if (@pmb.style == "Refend")
          when "Angle"
	        	case (self.style)
	        	when "Refend"
	        		path = $PMB_110_angle_rfd
	        	when "Ext"
	        		if (angle == "Gauche")
	          		if (style == "Exterieur")
	          			path = $PMB_110_angle_ext_gauche 
	          		else
	          			path = $PMB_110_angle_int_ext_gauche
	          		end
	        		elsif (angle == "Droite") 
	        			if (style == "Exterieur")
	        				path = $PMB_110_angle_ext_droite
	        			else
	        				path = $PMB_110_angle_int_ext_droite
	        			end
	        		end
	        	end
          else
              UI.messagebox "Type inconnu: " + element + " for " + nom
              return nil
           end
      when 100
        case (@pmb.type_bloc)
          when "Standard"
            path = $PMB_100_stand_ext if (@pmb.style == "Ext")
            path = $PMB_100_stand_rfd if (@pmb.style == "Refend")
          when "Demi"
            path = $PMB_100_demi_ext if (@pmb.style == "Ext")
            path = $PMB_100_demi_rfd if (@pmb.style == "Refend")
          when "Angle"
	        	case (self.style)
	        	when "Refend"
	        		path = $PMB_100_angle_rfd
	        	when "Ext"
	        		if (angle == "Gauche")
	          		if (style == "Exterieur")
	          			path = $PMB_100_angle_ext_gauche 
	          		else
	          			path = $PMB_100_angle_int_ext_gauche
	          		end
	        		elsif (angle == "Droite") 
	        			if (style == "Exterieur")
	        				path = $PMB_100_angle_ext_droite
	        			else
	        				path = $PMB_100_angle_int_ext_droite
	        			end
	        		end
	        	end
          else
              UI.messagebox "Type inconnu: " + element + " for " + nom
              return nil
           end
      when 70
        case (@pmb.type_bloc)
          when "Standard"
            path = $PMB_70_stand_ext if (@pmb.style == "Ext")
            path = $PMB_70_stand_rfd if (@pmb.style == "Refend")
          when "Demi"
            path = $PMB_70_demi_ext if (@pmb.style == "Ext")
            path = $PMB_70_demi_rfd if (@pmb.style == "Refend")
          when "Angle"
        	case (self.style)
        	when "Refend"
        		path = $PMB_70_angle_rfd
        	when "Ext"
        		if (angle == "Gauche")
          		if (style == "Exterieur")
          			path = $PMB_70_angle_ext_gauche 
          		else
          			path = $PMB_70_angle_int_ext_gauche
          		end
        		elsif (angle == "Droite") 
        			if (style == "Exterieur")
        				path = $PMB_70_angle_ext_droite
        			else
        				path = $PMB_70_angle_int_ext_droite
        			end
        		end
        	end
          else
              UI.messagebox "Type de bloc inconnu: " + element + " for " + nom
              return nil
           end
         end
      transform = Geom::Transformation.new(pt)
      model = Sketchup.active_model
      entities = model.active_entities
      model.description = "test"
      definitions = model.definitions
      componentdefinition = definitions.load path
      instance = entities.add_instance componentdefinition, transform
      instance.name = dimensions + ";" + @pmb.largeur.to_s + ";" + @pmb.type_bloc + "_" + angle +";" + @pmb.style if (angle)
			instance.name = dimensions + ";" + @pmb.largeur.to_s + ";" + @pmb.type_bloc + ";" + @pmb.style if !(angle)
      return @pmb.longueur, instance
    end    
    
    def self.creation_dessin(grp)
      mur =Mur.new()
      mur.recupere_option_dessin(grp)
      return mur
    end
    
    def max(x1,x2)
      if x1 > x2
        return x1
      else
        return x2
      end
    end
    
    def calcul_N_nb_angle(long)
      if (long == @L1)
        _N = @N1
        nb_angle = 1
      else
        _N = @N2
        nb_angle = 2
      end
      return _N, nb_angle
    end

    def calculs_parametres_fenetres(mur, coord)
	    if !(mur.objets_classes.empty?)
        $nom_fenetres = []
        $montage_fenetres = []
        $x_debut = []
        $x_fin = []
        $z_maxi = []
        $z_mini = []
        $z_mini_classes = []
	      parametres = mur.objets_classes
	      puts("parametres = #{mur.objets_classes.inspect}") if $DEBUG
	      parametres.each do |z|
	        $nom_fenetres.push(z.nom)
	        $montage_fenetres.push(z.montage)
	        $x_debut.push(z.x_debut)
	        $x_fin.push(z.x_fin)
	        $z_maxi.push(z.z_max.mm)
	        $z_mini.push(z.z_min.mm)
	      end
		  end 
		  $z_mini.push((mur.hauteur-$haut_pmb).mm) if ($z_mini.empty?)
	    $z_maxi.push(mur.hauteur.mm) if ($z_maxi.empty?)
	    $x_fin.push(mur.longueur) if($x_fin.empty?)

      $z_mini_classes = Array.new($z_mini.sort)
      $z_min_min = $z_mini_classes[0]
      $z_min_max = $z_mini_classes[-1]
      $z_mini_classes.push(mur.longueur.mm)

      $z_maxi_classes = Array.new($z_maxi.sort)
      $z_max = $z_maxi_classes[-1]
      
      $x_fin.push(mur.longueur)
      $minimum = $z_mini.sort[0]
      $maximum = $z_mini.sort[-1]
      return 
    end
 
    def calcul_parametres_maison(bloc = Bloc_PMB.new, nb_angle_rang = nil)
      # Calcul longueur mur PMB
      max_L = nil
      long_mur = self.longueur.to_i
      long_pmb = $long_pmb
      haut_pmb = bloc.hauteur
      larg_mur = largeur
      haut_mur = hauteur
      long_angle_pmb = (long_pmb / 2) + larg_mur
      @N1 = ((long_mur - long_angle_pmb - larg_mur)/long_pmb).to_int
      @N2 = ((long_mur - 2*long_angle_pmb)/long_pmb).to_int
      @L1 = @N1*long_pmb + long_angle_pmb + larg_mur
      @L2 = (@N2*long_pmb + 2*long_angle_pmb)
      puts("N1 = #{@N1} et L1 = #{@L1.mm}\nN2 = #{@N2} et L2 = #{@L2.mm}") if $VERBOSE
      max_L = max(@L1,@L2)
      puts(long_mur) if $VERBOSE
      puts("max_L = #{max_L}") if $VERBOSE
      case dimensions
      when "Standard"
        nb_bloc_rang, nb_angle_rang = calcul_N_nb_angle(max_L)
        long_mur = max_L
      when "Sur mesure"
      	if(max_L == long_mur)
      		self.dimensions = "Standard"
      		# self.mont_imp = false
      		# UI.messagebox("Stop")
      		return calcul_parametres_maison(bloc, nb_angle_rang)
      	end
        case nb_angle_rang
          when 1
            nb_bloc_rang = @N1
            max_L = @L1
          when 2
            nb_bloc_rang = @N2
            max_L = @L2
          when nil
            nb_bloc_rang, nb_angle_rang = calcul_N_nb_angle(max_L)
        end
        difference = (long_mur - max_L).round
        if (difference <= $long_pmb_demi) && (nb_bloc_rang != 0)
        	difference += $long_pmb
        	nb_bloc_rang -= 1
        elsif (difference == $long_pmb)
        	nb_bloc_rang += 1
        	difference = 0
        end
        @long_spec  = difference
      end
      return long_mur, nb_bloc_rang, nb_angle_rang
    end
    
    def recherche_ancien_mur(orig, fin, grp = Sketchup.active_model.entities)
      @mont_deb = nil
      @mont_fin = nil
      @num_deb  = nil
      @num_fin  = nil
      @mont_imp = false
      mur_courant = nom
      n_mur = (nom.delete('mur')).to_i
      for nb in 0...20 do
        ancien_mur = "mur" + nb.to_s
        grp.each do |ent|
          next if not (ent.kind_of?(Sketchup::Group))
          nom = ent.get_attribute('Info élément', 'nom')
          if (nom && (nom == ancien_mur))
            pts = ent.get_attribute('Info élément', "point_angle")
            for j in 0..3 do
              if (pts[j] == fin)
                @num_fin  = j
                @mont_fin = ent.get_attribute('Info élément', 'montage')
                @mont_imp = true
                # UI.messagebox("POINT FINAL TROUVE SUR LE: #{nom}")
              end
              break if @mont_fin
            end
            for i in 0..3 do
              if (pts[i] == orig)
                @num_deb = i
                @mont_deb = ent.get_attribute('Info élément', 'montage')
                # UI.messagebox("TROUVE POINT DE DEPART SUR LE: #{nom}")
              end
              break if @mont_deb
            end
            break if (@mont_deb && @mont_fin)
          end
        end
        break if (@mont_deb && @mont_fin)
      end
      @mont_imp = true if (@mont_deb && @mont_fin)
    end

    def ajoute_epure(origine, fin, long, larg)
      ancien = change_calque_actif(self.calque + "_epure",true)
      base_mur = creer_groupe(@base_mur)
      point_angle[0] = Geom::Point3d.new
      point_angle[1] = Geom::Point3d.new(long.mm, 0,0)
      point_angle[2] = Geom::Point3d.new(long.mm, larg.mm, 0)
      point_angle[3] = Geom::Point3d.new(0, larg.mm, 0)
      base_mur.entities.add_face(point_angle[0], point_angle[1] ,point_angle[2], point_angle[3])
      base_mur.entities.add_cline point_angle[0], $axe_X
      base_mur.entities.add_cline point_angle[1], $axe_Y
      base_mur.entities.add_cline point_angle[2], $axe_X
      base_mur.entities.add_cline point_angle[3], $axe_Y
      change_calque_actif(ancien,true)
      affiche_calque(self.calque + "_epure",true)
      self.epure = base_mur
      return base_mur
    end

    def choix_montage(nb_angle)
    	puts(nb_angle)
    	puts(montage)
    	puts(@mont_imp)
    	# UI.messagebox("stop")
      montage = nil
      if ((@num_deb==0||@num_deb==3)&&(@mont_deb=~/^\S2$/))\
         ||((@num_deb==1||@num_deb==2)&&(@mont_deb=="A2"||@mont_deb=="B1"))
        case @mont_imp
        when true
          montage = "A1" if ((@num_fin==0||@num_fin==3)&&(@mont_fin=~/^\S2$/))\
          ||((@num_fin==1||@num_fin==2)&&(@mont_fin=="A2"||@mont_fin=="B1"))\
          ||(@num_fin==nil && nb_angle == 2)
          montage = "B1" if ((@num_fin==0||@num_fin==3)&&(@mont_fin=~/^\S1$/))\
          ||((@num_fin==1||@num_fin==2)&&(@mont_fin=="A1"||@mont_fin=="B2"))\
          ||(@num_fin==nil && nb_angle == 1)
        else
          if @mont_fin == nil
            montage = "A1" if nb_angle == 2
            montage = "B1" if nb_angle == 1
          end
        end
      end
      if ((@num_deb==0||@num_deb==3)&&(@mont_deb=~/^\S1$/))\
         ||((@num_deb==1||@num_deb==2)&&(@mont_deb=="A1"||@mont_deb=="B2"))
        case @mont_imp
        when true
          montage = "A2" if (((@num_fin==0||@num_fin==3)&&(@mont_fin=~/^\S1$/))\
          ||((@num_fin==1||@num_fin==2)&&(@mont_fin=="A1"||@mont_fin=="B2"))\
          ||(@num_fin==nil && nb_angle == 2))
          montage = "B2" if (((@num_fin==0||@num_fin==3)&&(@mont_fin=~/^\S2$/))\
          ||((@num_fin==1||@num_fin==2)&&(@mont_fin=="A2"||@mont_fin=="B1"))\
          ||(@num_fin==nil && nb_angle == 1))
        else
          if @mont_fin == nil
            montage = "A2" if nb_angle == 2
            montage = "B2" if nb_angle == 1
          end
        end
      end
      if (@mont_deb == nil)
        if ((@num_fin==0||@num_fin==3)&&(@mont_fin=~/^\S1$/))\
          ||((@num_fin==1||@num_fin==2)&&(@mont_fin=="A1"||@mont_fin=="B2"))
          montage = "A2" if nb_angle == 2
          montage = "B1" if nb_angle == 1
        end
        if ((@num_fin==0||@num_fin==3)&&(@mont_fin=~/^\S2$/))\
          ||((@num_fin==1||@num_fin==2)&&(@mont_fin=="A2"||@mont_fin=="B1"))
          montage = "A1" if nb_angle == 2
          montage = "B2" if nb_angle == 1
        end
        if (@mont_fin == nil) 
          montage = "A1" if nb_angle == 2
          montage = "B1" if nb_angle == 1
        end
      end
      if @mont_imp
        nb_angle = 2 if montage =~ /^A\w$/
        nb_angle = 1 if montage =~ /^B\w$/
        self.dimensions = "Sur mesure"
      end
      return montage, nb_angle
    end
    
    def recherche_zone(mur, coord)
      z = coord.z
      x = coord.x
      zone = nil
      indice = nil
      if(z==0)||(z==(mur.hauteur-$haut_pmb).mm)
        zone = "zone_B"
      elsif((z<$z_min_min)||((z>$z_max)&&(z<(mur.hauteur-$haut_pmb).mm)))
        zone = "zone_A"
      else
        x_debut = mur.longueur.mm
        mur.objets_classes.each do |fen|
          if(x >= fen.x_debut.mm)
            if((objets_classes.index(fen)+1) == (objets_classes.length))
              zone = "zone_D"
            end
          elsif(z >= fen.z_min.mm)
              if(fen.x_debut.mm < x_debut)
                $indice_suivant = objets_classes.index(fen)
                x_debut = fen.x_debut.mm
                if (x == 0)
                  zone = "zone_C"
                else
                  zone = "zone_E"
                end
              end
          elsif(x_debut == mur.longueur.mm)
            zone = "zone_D"
          end
        end
      end
      return zone
    end
    
    def determiner_zone_mur(mur,coord)
      $zone_A = $zone_B = $zone_C = $zone_D = $zone_E = nil
      zone = recherche_zone(mur,coord)
      $zone_A = true if (zone == "zone_A")
      $zone_B = true if (zone == "zone_B")
      $zone_C = true if (zone == "zone_C")
      $zone_D = true if (zone == "zone_D")
      $zone_E = true if (zone == "zone_E")
    end
    
    def draw_Zone_A(entite, long_mur, long_angle_pmb, nb_bloc_rang, pair, coord)
      # Calcul du premier bloc d'angle
      if not pair
        long, element = ajoute_bloc(coord,"Angle","Gauche",self.style_angle_gauche)
        entite.push(element)
        coord.x += long.mm
        #UI.messagebox(long)
      else
        coord.x += largeur.mm
      end
        
      nb_bloc = nb_bloc_rang
      nb_bloc += 1 if (pair && ($nb_angle != 1))
      for i in 1..(nb_bloc) do
        long, grp = ajoute_bloc(coord,"Standard")
        entite.push(grp)
        coord.x += long.mm
        i += 1
      end
      # Construction du dernier bloc qui peut être "sur mesure"
      case dimensions
        when 'Standard'
          # ne rien faire
        when 'Sur mesure'
          special = @long_spec
          #puts("nb_bloc = #{nb_bloc}")
          if nb_bloc == 0
            special = (@long_spec) if (!pair && ($nb_angle == 2)) || (pair && ($nb_angle == 1))
          end
          #puts("special = #{special}")
          long, grp = ajoute_bloc(coord,"standard",nil,"","Sur mesure",special)
      		grp.name = long.to_s + ";" + largeur.to_s + ";" + "Compensation" + ";" +style
		      entite.push(grp)
		      coord.x += long.mm
        end
  		# Calcul du dernier bloc d'angle
  		coord.x = (long_mur - long_angle_pmb).mm
  		if (montage =~ /^A\w$/ && !pair)||(montage =~ /^B\w$/ && pair)
  			long, element = ajoute_bloc(coord,"Angle","Droite",self.style_angle_droite)
  			entite.push(element)
  			coord.x += long.mm
  		end
	    return entite, coord
    end
    
    def draw_Zone_B(entite, long_mur, larg_mur, pair, long_angle_pmb, montage, long_linteau, coord)
      # Calcul du premier bloc d'angle
      if not pair
        long, grp = ajoute_bloc(coord,"Angle","Gauche",self.style_angle_gauche)
        entite.push(grp)
        coord.x += long.mm
        #UI.messagebox(long)
      else
        coord.x += largeur.mm
      end
        
      long_ceinture = long_mur - 2*larg_mur if pair && (montage =~ /^A\w$/)
      long_ceinture = long_mur - 2*($long_pmb_demi + larg_mur) if !pair && (montage =~ /^A\w$/)
      long_ceinture = long_mur - $long_pmb_demi - 2*larg_mur if (montage =~ /^B\w$/)
      #puts(self.inspect)
      nb_bloc = (long_ceinture/$long_linteau).truncate
      ecart = (long_ceinture%$long_linteau).round
      puts("long_ceinture: #{long_ceinture}") if $DEBUG_ZONE_B
      puts("ecart avant: #{ecart}") if $DEBUG_ZONE_B
      puts("nb de bloc avant: #{nb_bloc}") if $DEBUG_ZONE_B
      linteau = $long_linteau
      if(ecart < ($long_linteau*4/5)) && (ecart != 0) && (nb_bloc != 0)
      	nb_bloc += 1
      	linteau = (long_ceinture / nb_bloc)
      	k = (linteau / $long_pmb)
      	puts("k = #{k}") if $DEBUG_ZONE_B
      	k = k.truncate
      	linteau = k * $long_pmb
      	nb_bloc = (long_ceinture / linteau).to_int
      	ecart = (long_ceinture % linteau).round
	      puts("ecart après: #{ecart}") if $DEBUG_ZONE_B
	      puts("nb de bloc après: #{nb_bloc}") if $DEBUG_ZONE_B
      	puts("long linteau après: #{long_linteau}") if $DEBUG_ZONE_B
      end
      for i in 1..nb_bloc do
        long, grp = ajoute_bloc(coord,"Standard", nil, "", "Sur mesure", linteau)
        long_ceinture -= linteau
        grp.name = long.to_s+";"+self.largeur.to_s+";"+"Lisse basse"+";"+self.style if coord.z==0
        grp.name = long.to_s+";"+self.largeur.to_s+";"+"Linteau"+";"+self.style if coord.z!=0
        entite.push(grp)
        coord.x += long.mm
      end
      if (long_ceinture!=0)
        long, grp = ajoute_bloc(coord,"Standard", nil, "", "Sur mesure", ecart)
        grp.name = long.to_s + ";" + largeur.to_s + ";" + "Linteau" + ";" +style if coord.z!=0
        grp.name = long.to_s + ";" + largeur.to_s + ";" + "Lisse basse" + ";" +style if coord.z==0
        entite.push(grp)
        coord.x += long.mm
      end
  		if (montage =~ /^A\w$/ && !pair)||(montage =~ /^B\w$/ && pair)
  			long, grp = ajoute_bloc(coord,"Angle", "Droite", self.style_angle_droite)
  			entite.push(grp)
  			coord.x += long.mm
  		end
	    return entite, coord
    end
    
    def calcul_zone_C(coord, rang_pair)
      $fenetre_active = objets_classes[$indice_suivant]
      montage_suivant = $fenetre_active.montage
      montage_mur = self.montage
      if (montage_mur =~/^\S1$/)
      	pair = rang_pair # rien ne change
      else
      	pair = !rang_pair # inversion de la parité
      end
      $origine_x_fin = $fenetre_active.x_fin
      x_fin = $fenetre_active.x_debut
      puts($fenetre_active.inspect) if $DEBUG_ZONE_C
      puts("x_fin = #{x_fin}") if $DEBUG_ZONE_C
      parite_z_max = ($fenetre_active.z_max / $haut_pmb) % 2 == 0
      if !parite_z_max
	      if ((((montage_suivant == "B")||(montage_suivant == "D")||(montage_suivant == "J")||(montage_suivant == "L")) &&  pair) ||
	      		(((montage_suivant == "A")||(montage_suivant == "C")||(montage_suivant == "I")||(montage_suivant == "K")) && !pair)) ||
	      		((((montage_suivant == "Aa")||(montage_suivant == "Ca")||(montage_suivant == "Ia")||(montage_suivant == "La")||(montage_suivant == "Ka")) &&  pair) ||
	      		(((montage_suivant == "Ba")||(montage_suivant == "Da")||(montage_suivant == "Ja")) && !pair))
	    		x_fin -= $long_pmb_demi
	    	else
	    		x_fin -= $long_pmb
	    	end
      else
	      if ((((montage_suivant == "A")||(montage_suivant == "C")||(montage_suivant == "I")||(montage_suivant == "K")) &&  pair) ||
	      		(((montage_suivant == "B")||(montage_suivant == "D")||(montage_suivant == "J")||(montage_suivant == "L")) && !pair)) ||
	      		((((montage_suivant == "Aa")||(montage_suivant == "Ca")||(montage_suivant == "Ia")||(montage_suivant == "La")||(montage_suivant == "Ka")) &&  pair) ||
	      		(((montage_suivant == "Ba")||(montage_suivant == "Da")||(montage_suivant == "Ja")) && !pair))
	    		x_fin -= $long_pmb_demi
	    	else
	    		x_fin -= $long_pmb
	    	end
      end
    	x_debut = coord.x.to_mm.to_i
    	
    	long_C = (x_fin - x_debut).round
    	if long_C < 0
    		long_C = 0
    	end
    	
      coord.x = x_debut.mm
      
      nb_bloc_C = (long_C/$long_pmb).to_int
      ecart = (long_C % $long_pmb).round
      puts("ecart = #{ecart}\n\n") if $DEBUG_ZONE_C
      if (ecart <= $long_pmb_demi) && (ecart != 0)  
      	ecart += $long_pmb
      	nb_bloc_C -= 1
      end if (nb_bloc_C > 0) 
      puts("pair = #{pair}") if $DEBUG_ZONE_C
      puts("long_C = #{long_C.to_f}") if $DEBUG_ZONE_C
      puts("montage_suivant = #{montage_suivant}") if $DEBUG_ZONE_C
      puts("nb_bloc_C = #{nb_bloc_C}")  if $DEBUG_ZONE_C
      return nb_bloc_C, ecart
    end
    
    def calcul_zone_D(coord, rang_pair)
      montage_fenetre = $fenetre_active.montage
      montage_mur = self.montage
      if (montage_mur =~/^\S1$/)
      	pair = rang_pair # rien ne change
      else
      	pair = !rang_pair # inversion de la parité
      end
      x_debut = $fenetre_active.x_fin
      UI.messagebox($fenetre_active.inspect) if $DEBUG_FENETRE
      UI.messagebox($fenetre_active.inspect) if $DEBUG_FENETRE
      parite_z_max = ($fenetre_active.z_max / $haut_pmb) % 2 == 0
      if !parite_z_max
	      if ((((montage_fenetre == "B")||(montage_fenetre == "C")||(montage_fenetre == "F")||(montage_fenetre == "G")) &&  pair) ||
	      		(((montage_fenetre == "A")||(montage_fenetre == "D")||(montage_fenetre == "E")||(montage_fenetre == "H")) && !pair))||
	      		((((montage_fenetre == "Bb") || (montage_fenetre == "Cb")||(montage_fenetre == "Fb")) &&  pair) ||
	      		(((montage_fenetre == "Ab") || (montage_fenetre == "Db")||(montage_fenetre == "Eb")||(montage_fenetre == "Gb")||(montage_fenetre == "Hb")) && !pair))
	    		x_debut += $long_pmb_demi
	    	else
	    		x_debut += $long_pmb
	    	end
      else
	      if ((((montage_fenetre == "A")||(montage_fenetre == "D")||(montage_fenetre == "E")||(montage_fenetre == "H")) &&  pair) ||
	      		(((montage_fenetre == "B")||(montage_fenetre == "C")||(montage_fenetre == "F")||(montage_fenetre == "G")) && !pair))||
	      		((((montage_fenetre == "Ab")||(montage_fenetre == "Db")||(montage_fenetre == "Eb")) &&  pair) ||
	      		(((montage_fenetre == "Bb")||(montage_fenetre == "Cb")||(montage_fenetre == "Fb")||(montage_fenetre == "Gb")||(montage_fenetre == "Hb")) && !pair))
	    		x_debut += $long_pmb_demi
	    	else
	    		x_debut += $long_pmb
	    	end
      end
       if (montage_mur =~ /^A\w$/ && !rang_pair)||(montage_mur =~ /^B\w$/ && rang_pair)
      	x_fin = self.longueur - self.largeur - $long_pmb_demi
      else
      	x_fin = self.longueur - self.largeur
      end
      
      coord.x = x_debut.mm
      long_D = (x_fin - x_debut).round
      if long_D < 0
      	long_D = 0
      end
                                     
      nb_bloc_D = ((long_D/$long_pmb)).to_int
      puts("nb_bloc_D = #{nb_bloc_D}") if $DEBUG_ZONE_D
      ecart = (long_D % $long_pmb).round 
      puts("ecart = #{ecart}") if $DEBUG_ZONE_D
      if (ecart <= $long_pmb_demi) && (ecart != 0) && (nb_bloc_D != 0)
      	ecart += $long_pmb
      	nb_bloc_D -= 1
      end 
      puts("x_debut = #{x_debut}") if $DEBUG_ZONE_D
      puts("x_fin = #{x_fin}") if $DEBUG_ZONE_D
      puts("long_D = #{long_D}") if $DEBUG_ZONE_D
      puts("nb_bloc_D = #{nb_bloc_D}") if $DEBUG_ZONE_D
      puts("ecart = #{ecart}") if $DEBUG_ZONE_D
      puts("parité paire = #{pair}") if $DEBUG_ZONE_D
      return nb_bloc_D, ecart, coord
    end
    
    def calcul_zone_E(coord, rang_pair) 
      fenetre_precedente = $fenetre_active
      puts("fenetre_precedente = #{fenetre_precedente.inspect}\n\n") if $DEBUG_ZONE_E
      montage_precedent = fenetre_precedente.montage
      montage_mur = self.montage
      if (montage_mur =~/^\S1$/)
      	pair = rang_pair # rien ne change
      else
      	pair = !rang_pair # inversion de la parité
      end
      x_debut = fenetre_precedente.x_fin
      $fenetre_active = objets_classes[$indice_suivant]
      puts("fenetre_active = #{$fenetre_active.inspect}\n\n") if $DEBUG_ZONE_E
      if (($fenetre_active.x_debut - fenetre_precedente.x_debut) <= (3*$long_pmb/2))
        if($fenetre_active.montage == "A")
          $fenetre_active.montage = "B"
        elsif($fenetre_active.montage == "B")
          $fenetre_active.montage = "A"
        elsif($fenetre_active.montage == "C")
          $fenetre_active.montage = "D"
        elsif($fenetre_active.montage == "D")
          $fenetre_active.montage = "C"
        end
      end
      $fenetre_active_index = objets_classes.index($fenetre_active)
      montage_suivant =$fenetre_active.montage
      x_fin = $fenetre_active.x_debut
      $origine_x_fin = $fenetre_active.x_fin

      puts("x_debut = #{x_debut}") if $DEBUG_ZONE_E
      puts("x_fin = #{x_fin}") if $DEBUG_ZONE_E
      parite_z_max = ($fenetre_active.z_max / $haut_pmb) % 2 == 0
      if !parite_z_max      	
	      if ((((montage_precedent == "B")||(montage_precedent == "C")||(montage_precedent == "F")||(montage_precedent == "G")) &&  pair) ||\
	          (((montage_precedent == "A")||(montage_precedent == "D")||(montage_precedent == "E")||(montage_precedent == "H")) && !pair))||
	          ((((montage_precedent == "Bb")||(montage_precedent == "Cb")||(montage_precedent == "Fb")||(montage_precedent == "Gb")) &&  pair) ||\
	          (((montage_precedent == "Ab")||(montage_precedent == "Db")||(montage_precedent == "Eb")||(montage_precedent == "Hb")) && !pair))
	        x_debut += $long_pmb_demi 
	      elsif !((montage_precedent =~/^\Sa$/)||(montage_precedent =~/^\Sc$/))
	      	x_debut += $long_pmb
	      end
	      if ((((montage_suivant == "B")||(montage_suivant == "D")||(montage_suivant == "J")||(montage_suivant == "L")) &&  pair) ||\
	          (((montage_suivant == "A")||(montage_suivant == "C")||(montage_suivant == "I")||(montage_suivant == "K")) && !pair))
	        x_fin -= $long_pmb_demi 
	      elsif !((montage_suivant =~/^\Sb$/)||(montage_suivant =~/^\Sc$/))
	      	x_fin -= $long_pmb
	      end
      else
	      if ((((montage_precedent == "A")||(montage_precedent == "D")||(montage_precedent == "E")||(montage_precedent == "H")) &&  pair) ||\
	          (((montage_precedent == "B")||(montage_precedent == "C")||(montage_precedent == "F")||(montage_precedent == "G")) && !pair))||
	          ((((montage_precedent == "Ab")||(montage_precedent == "Db")||(montage_precedent == "Eb")||(montage_precedent == "Hb")) &&  pair) ||\
	          (((montage_precedent == "Bb")||(montage_precedent == "Cb")||(montage_precedent == "Fb")||(montage_precedent == "Gb")) && !pair))
	        x_debut += $long_pmb_demi 
	      elsif !((montage_precedent =~/^\Sa$/)||(montage_precedent =~/^\Sc$/))
	      	x_debut += $long_pmb
	      end
	      if ((((montage_suivant == "A")||(montage_suivant == "C")||(montage_suivant == "I")||(montage_suivant == "K")) &&  pair) ||\
	          (((montage_suivant == "B")||(montage_suivant == "D")||(montage_suivant == "J")||(montage_suivant == "L")) && !pair))
	        x_fin -= $long_pmb_demi 
	      elsif !((montage_suivant =~/^\Sb$/)||(montage_suivant =~/^\Sc$/))
	      	x_fin -= $long_pmb
	      end
      end
      long_E = (x_fin - x_debut).round
      puts("long_E = #{long_E}") if $DEBUG_ZONE_E
      long_E = 0 if (montage_precedent =~/^\Sa$/ || montage_precedent =~/^\Sc$/) && ((coord.z==$fenetre_active.z_max.mm)||
      							(coord.z==$fenetre_active.z_min.mm) && ($fenetre_active.nom.to_s =~/^fenetre\w$/))
      							
      					
      if long_E < 0
      	long_E = 0
      end
      coord.x = x_debut.mm
      
      puts("pair = #{pair}") if $DEBUG_ZONE_E
      puts("x_debut = #{x_debut}") if $DEBUG_ZONE_E
      puts("x_fin = #{x_fin}") if $DEBUG_ZONE_E
      puts("x = #{coord.x}") if $DEBUG_ZONE_E
      puts("long_E = #{long_E}") if $DEBUG_ZONE_E
      puts("montage_precedent = #{montage_precedent}") if $DEBUG_ZONE_E
      puts("montage_actuel = #{montage_suivant}") if $DEBUG_ZONE_E
      #UI.messagebox("Stop !") if $DEBUG_ZONE_E

      nb_bloc_E = (long_E/$long_pmb).to_int
      puts("nb_bloc_E = #{nb_bloc_E}") if $DEBUG_ZONE_E
      ecart = (long_E%$long_pmb).round
      puts("ecart = #{ecart}") if $DEBUG_ZONE_E
      demi_bloc_E = 0
      if (ecart < $long_pmb_demi) && (ecart != 0) && (nb_bloc_E != 0)
      	ecart += $long_pmb
      	nb_bloc_E -= 1
      end 
      if (ecart == $long_pmb_demi) && ((montage_suivant =~/^\Sb$/)||(montage_suivant =~/^\Sc$/))
      	demi_bloc_E = 1
      	ecart = 0 
      elsif (nb_bloc_E == 1) && !pair && ((montage_suivant =~/^\Sb$/)||(montage_suivant =~/^\Sc$/))
      	demi_bloc_E = 2
      	nb_bloc_E = 0
      end

      return nb_bloc_E, demi_bloc_E, ecart, coord
    end
    
    def draw_Zone_C(entite, coord, pair)
    	montage = objets_classes[$indice_suivant].montage
	    if !(montage == "E" || montage == "F" || montage == "G" || montage == "H"||montage == "Ea" || montage == "Fa" || montage == "Ga" || montage == "Ha")
	    	# Calcul du premier bloc d'angle
	      if not pair
	        long, element = ajoute_bloc(coord,"Angle","Gauche",self.style_angle_gauche)
	        entite.push(element)
	        coord.x += long.mm
	        #UI.messagebox(long)
	      else
	        coord.x += largeur.mm
	      end
      else
      	if not pair
      		coord.x += ($long_pmb_demi + largeur).mm
      	else
      		coord.x += largeur.mm
      	end	      	
      end

    	nb_bloc, difference = calcul_zone_C(coord, pair)

  		for i in 1..nb_bloc
  			long, grp = ajoute_bloc(coord,"Standard")
  			entite.push(grp)
  			coord.x += long.mm
  		end
  		if(difference != 0)
  		  long, grp = ajoute_bloc(coord,"Standard",nil,"", "Sur mesure", difference)
        grp.name = long.to_s + ";" + largeur.to_s + ";" + "Compensation" + ";" +style
        entite.push(grp)
        coord.x += long.mm
      end
      coord.x = $origine_x_fin.mm
      return entite, coord
		end

    def draw_Zone_D(entite, coord, pair)
  		nb_bloc, difference, coord = calcul_zone_D(coord, pair)
  		for i in 1..nb_bloc
  			long, grp = ajoute_bloc(coord,"Standard")
  			entite.push(grp)
  			coord.x += long.mm
  		end
  		if(difference !=0)
  		  long, grp = ajoute_bloc(coord,"Standard",nil,"", "Sur mesure", difference)
        grp.name = long.to_s + ";" + largeur.to_s + ";" + "Compensation" + ";" +style
        entite.push(grp)
        coord.x += long.mm
      end
	    if !(montage == "I" || montage == "J" || montage == "K" || montage == "L"||montage == "Ia" || montage == "Ja" || montage == "Ka" || montage == "La")
	  		if ((montage =~ /^A\w$/ && !pair)||(montage =~ /^B\w$/ && pair))
	  			long, element = ajoute_bloc(coord,"Angle", "Droite", self.style_angle_droite)
	  			entite.push(element)
	  			coord.x += long.mm
	  		end
	    end
      return entite, coord
		end

    def draw_Zone_E(entite, coord, pair)
      nb_bloc, demi_bloc_E, difference, coord = calcul_zone_E(coord, pair)
      
      for i in 1..demi_bloc_E
        long, grp = ajoute_bloc(coord,"Demi")
        entite.push(grp)
        coord.x += long.mm
      end
       
      for i in 1..nb_bloc
        long, grp = ajoute_bloc(coord,"Standard")
        entite.push(grp)
        coord.x += long.mm
      end
      if(difference !=0)
        long, grp = ajoute_bloc(coord,"Standard", nil, "","Sur mesure", difference)
        grp.name = long.to_s + ";" + largeur.to_s + ";" + "Compensation" + ";" +style
        entite.push(grp)
        coord.x += long.mm
      end
      coord.x = $origine_x_fin.mm
      return entite, coord
		end

    def draw()
      modele = Sketchup.active_model
      ensemble_mur = []
      coord = Geom::Point3d.new
      coord_debut_normal = Geom::Point3d.new
      $nom_fenetres = []
      $montage_fenetres = []
      $x_debut =[]
      $x_fin = []
      $z_maxi = []
      $z_mini = []
      $z_mini_classes = []
      $fenetre_active_index = 0
      $indice_suivant = nil
      $indice_actuel = nil
			$liste_composant_fenetre = []
      @semelle = Semelle_betonPMB.new(remplir_options(
        %w[style layer],
        'calque'        => "Fondations",
        'long_sem'      => longueur,
        'angle'         => angle,
        'pt_debut'      => pt_debut,
        'pt_fin'        => pt_fin,
        'justification' => justification
      ))
      @pmb = Bloc_PMB.new(remplir_options(
        %w[style layer],
       	'calque'  => self.calque,
        'style'   => self.style,
        'largeur' => self.largeur
        
      ))
      fenetre = Fenetre.new()
      fenetre.classer_objets(self)
      calculs_parametres_fenetres(self, coord)
      # ------------------------------ Construction du mur --------------------------------
      recherche_ancien_mur(pt_debut, pt_fin)
      @mont_imp = true if dimensions == "Sur mesure"

      # ------------------------------ Construction du mur --------------------------------
      # Calcul des paramètres de construction
      # -------------------------------------
      self.pair = false
      nb_bloc_rang = nil
      nb_angle_rang = nil
      long_pmb = $long_pmb
      haut_pmb = @pmb.hauteur
      $long_linteau = @pmb.long_linteau
      larg_mur = self.largeur
      haut_mur = self.hauteur
      long_angle_pmb = (long_pmb / 2.0) + larg_mur
      nb_rang = (haut_mur/ haut_pmb)
      
      long_mur, nb_bloc_rang, $nb_angle = calcul_parametres_maison(@pmb)
      self.montage, $nb_angle = choix_montage($nb_angle) if (montage == nil)
      long_mur, nb_bloc_rang, $nb_angle = calcul_parametres_maison(@pmb,$nb_angle) if @mont_imp
      self.longueur = long_mur
 
      # -----------------------------------------------------------------------------------
      
      # Contruction de la semelle beton
      # semelles = creer_semelle(coord)

      # Construction du mur
      for rang in 1..nb_rang do
        #rotate($z_mini_classes) if (coord.z == $z_mini_classes[1]) 
        parties_mur = []
        pair = false
        if (montage =~/^\S1$/)
          pair = true if !(rang%2!=0)
        else
          pair = true if (rang%2!=0)
        end
        
        coord_debut_normal = coord

        determiner_zone_mur(self,coord)

        if ($zone_A)
    			# Construction de la rangée de (N-1) premier bloc PMB
    			parties_mur, coord = draw_Zone_A(parties_mur, long_mur, long_angle_pmb, nb_bloc_rang, pair, coord)
    		elsif ($zone_B)
    			# Pose de la ceinture (linteau)
    			parties_mur, coord = draw_Zone_B(parties_mur, long_mur, larg_mur, pair, long_angle_pmb, montage, $long_linteau, coord)
    		elsif ($zone_C)
    			parties_mur, coord = draw_Zone_C(parties_mur, coord, pair)
    			determiner_zone_mur(self,coord)
    			#UI.messagebox(recherche_zone(self,coord))
          while($zone_E)
            parties_mur, coord = draw_Zone_E(parties_mur, coord, pair)
            determiner_zone_mur(self,coord)
          end
          montage_fen = objets_classes[$indice_suivant].montage
          if ($zone_D)&& !(montage_fen=="I"||montage_fen=="J"||montage_fen=="K"||montage_fen=="L")
            parties_mur, coord = draw_Zone_D(parties_mur, coord, pair)
          end
    		end
    		
        ensemble_mur += parties_mur
        coord.x = pt_offset.x.mm
        puts coord.x.mm if $DEBUG
        coord.z += haut_pmb.mm
        rang += 1
      end

      nombre = @objets.length
      fenetre_intermediaire = nil
      index = nil
      @objets.each do |objet|
      	if (objet.montage =~/^\Sc$/)
      		index = @objets.index(objet)
      		fenetre_intermediaire = objet
      		#ensemble_mur.push(fenetre_intermediaire.table)
      		#next
      	end
        long, partie_objet = objet.dessine_objet(self, coord, objet)
        ensemble_mur.push(partie_objet) if (partie_objet != nil)
        coord = coord.set!(long) if (partie_objet != nil)
        nombre -= 1
        next if nombre < 1
      end
            
      coord.x = pt_offset.x
      puts coord.x.mm if $DEBUG
 
      if ((nb_bloc_rang==0) || @mont_imp)
        self.dimensions = "Standard"
        @impose = false
      end
      # +---------------------------------------------------------------------------------+
      # |             Dessine la partie haute des pignons lorsque c'est le cas            | 
      # +---------------------------------------------------------------------------------+
	    case self.class.to_s
	      when "PMB::Pignon"
	        partie_objet = dessine_pignon()
        	ensemble_mur.push(partie_objet)
	      	
	      when "PMB::Mur"
	      	# dessin du mur
	    end
	    #UI.messagebox(self.inspect) 
      # +---------------------------------------------------------------------------------+
      # |             Calculs des coordonnées des quatres angles reels                    | 
      # |                et dessine de la zone sur un nouveau calque                      |
      # +---------------------------------------------------------------------------------+
      self.epure.push(ajoute_epure(pt_debut, pt_fin, long_mur, larg_mur))
      # ----------------- Assemblage des différentes parties du mur -----------------------
      murs = modele.active_entities.add_group(ensemble_mur)
      id_materiel = modele.materials
      id_texture = id_materiel.add "Murs"
      id_texture.texture = $Texture_bois
      murs.material = id_texture
      
      # -------------------- Décalages, déplacemant et rotations --------------------------
      case justification
        when 'Gauche'
          point_zero = Geom::Point3d.new(0,0,0)
        when 'Centre'
          point_zero = Geom::Point3d.new(0,largeur.mm/2.0,0)
        when 'Droite'
          point_zero = Geom::Point3d.new(0,largeur.mm,0)
        end
      vec = Geom::Point3d.new - point_zero
      calage_justification = Geom::Transformation.new(vec)
      murs.transform!(calage_justification)
      for i in 0..3 do point_angle[i].transform!(calage_justification) end 
      epure.transform!(calage_justification)
      #semelles.transform!(calage_justification)

      rotation_mur = Geom::Transformation.new([0,0,0],[0,0,1],(self.angle+90).degrees)
      murs.transform!(rotation_mur)
      #semelles.transform!(rotation_mur)
      for i in 0..3 do point_angle[i].transform!(rotation_mur) end 
      epure.transform!(rotation_mur)

      replace_orig = Geom::Transformation.new(pt_debut)
      murs.transform!(replace_orig)
      for i in 0..3 do point_angle[i].transform!(replace_orig) end 
      epure.transform!(replace_orig)
      #semelles.transform!(replace_orig)
      #UI.messagebox(self.inspect)
      #self.pt_fin = point_angle[1]
      #UI.messagebox(self.inspect)
      # ------------------- Sauvegarde des groupes de dessin ------------------------------
      sauve_options_dessin(murs)
      epure.set_attribute("Info élément", "nom", self.nom + "_epure")
      epure.set_attribute("Info élément", "type", table[:type])
      return murs, epure
    end

  end # class Mur
  # ----------------------- MURS --------------------------------------
end # module PMB

