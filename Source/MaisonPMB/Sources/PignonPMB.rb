module PMB
	class Pignon < Mur
		attr_accessor :objets_classes_pignon
		def initialize(options = {})
      defaut_options_pignon = {
        'element'         	=> 'Pignon',
        'nom'             	=> '',
        'pente'							=> 45,
        'type_toit'					=> "2 pentes /\\",
        'angle'           	=> 0,
        'liste_composant'   => "",
      }
      applique_options_globales(defaut_options_pignon)
      defaut_options_pignon.update(options)
      @objets_classes_pignon = []
      super(defaut_options_pignon)
      if (self.nom.length == 0)
        self.nom = PMB::Base_PMB.nom_unique("pignon")
      end
      #puts(self.inspect)
      change_calque_actif(self.calque,true)
		end
		
    def options_Pignons(obj = self)
			proprietes_pignons = [
        ["Justification  ", "mur.justification"    , "Gauche|Centre|Droite" ],
        ["Dimensionnement", "mur.dimensions"   		 , "Standard|Sur mesure"],
        ["Hauteur du mur" , "mur.hauteur"          , nil],
        ["Largeur du mur" , "mur.largeur"          , "190|140|110|100|70"],
        ["Type de mur"    , "mur.style"            , "Ext|Refend"],
		    ["Pente en degrée", "Pignon.pente"     , nil ],
		    ["type de toit"   , 'Pignon.type_toit' , "1 pente __\\|1 pente /__|2 pentes /\\"],
			].freeze
      results = affiche_dialogue("Propriétés des pignons", obj, proprietes_pignons)
      return false if not results
      obj.hauteur = corrige_hauteur(obj.hauteur) if ((obj.hauteur.to_f % $haut_pmb)!=0)
      return results
    end
    
		def self.creation_pour_dessin(group)
	    mur = Pignon.new()
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
            UI.messagebox "Type inconnu: " + element + " pour " + nom
        end
      end
	    return mur
		end
		
    def creer_bloc_bord_pignon_gauche(point, longueur, decalage)
    	longueur_bloc, bloc = self.creer_bloc(point ,"Refend","Sur mesure", longueur, "Refend")
			entite = bloc.entities
			haut_maxi = (longueur * Math.tan(pente*Math::PI/180)) 
			if (haut_maxi >= $haut_pmb)
				haut_maxi = $haut_pmb
			else
				decalage = haut_maxi / Math.tan(pente*Math::PI/180)
				pt = []
				pt[0] = Geom::Point3d.new(point.x, 0, haut_maxi.mm + point.z)
				pt[1] = Geom::Point3d.new(point.x, 0, $haut_pmb.mm + point.z)
				pt[2] = Geom::Point3d.new(point.x + longueur.mm, 0, $haut_pmb.mm + point.z)
				pt[3] = Geom::Point3d.new(point.x + longueur.mm, 0, haut_maxi.mm + point.z)
				face = entite.add_face pt
				line = entite.add_line pt[0], pt[3]
				face.followme line 
			end

			pt = []
			pt[0] = Geom::Point3d.new(point.x, 0, point.z)
			pt[1] = Geom::Point3d.new(point.x, 0, haut_maxi.mm+point.z)
			pt[2] = Geom::Point3d.new(point.x + decalage.mm, 0, haut_maxi.mm+point.z)
			face = entite.add_face pt 
			pt[3] = Geom::Point3d.new(point.x + @offset_chanfrein.mm, 0, point.z + $haut_pmb.mm - @pmb.chanfrein.mm)
			pt[4] = Geom::Point3d.new(point.x + longueur.mm, 0, point.z + $haut_pmb.mm - @pmb.chanfrein.mm)
			line_chanfrein = entite.add_line pt[3], pt[4] if((self.style == "Ext") && (haut_maxi >= $haut_pmb))
			line = entite.add_line pt[1], Geom::Point3d.new(point.x, self.largeur.mm, haut_maxi.mm+point.z)
			face.followme line
			return longueur_bloc.round, bloc
    end

    def creer_bloc_bord_pignon_droit(point, longueur, decalage)
			longueur_bloc, bloc = self.creer_bloc(point , "Standard", "Sur mesure", longueur, "Refend")
			entite = bloc.entities
			haut_maxi = (longueur * Math.tan(pente*Math::PI/180)) 
			if (haut_maxi >= $haut_pmb)
				haut_maxi = $haut_pmb
			else
				decalage = haut_maxi / Math.tan(pente*Math::PI/180)
				pt = []
				pt[0] = Geom::Point3d.new(point.x, 0, haut_maxi.mm + point.z)
				pt[1] = Geom::Point3d.new(point.x, 0, $haut_pmb.mm + point.z)
				pt[2] = Geom::Point3d.new(point.x + longueur.mm, 0, $haut_pmb.mm + point.z)
				pt[3] = Geom::Point3d.new(point.x + longueur.mm, 0, haut_maxi.mm + point.z)
				face = entite.add_face pt
				line = entite.add_line pt[0], pt[3]
				face.followme line 
			end

			pt = []
			pt[0] = Geom::Point3d.new(longueur.mm + point.x, 0, point.z);
			pt[1] = Geom::Point3d.new(longueur.mm + point.x, 0, haut_maxi.mm+point.z);
			pt[2] = Geom::Point3d.new((longueur-decalage).mm + point.x, 0, haut_maxi.mm+point.z);
			face = entite.add_face pt 
			pt[3] = Geom::Point3d.new(point.x , 0, point.z + $haut_pmb.mm - @pmb.chanfrein.mm)
			pt[4] = Geom::Point3d.new(point.x + longueur.mm - @offset_chanfrein.mm, 0, point.z + $haut_pmb.mm - @pmb.chanfrein.mm)
			line_chanfrein = entite.add_line pt[3], pt[4] if((self.style == "Ext") && (haut_maxi >= $haut_pmb))
			line = entite.add_line pt[1], Geom::Point3d.new(point.x + longueur.mm, self.largeur.mm, haut_maxi.mm+point.z)
			face.followme line
			return longueur_bloc.round, bloc
    end

    def creer_bloc_haut_pignon(point, longueur, decalage)
			longueur_bloc, bloc = self.creer_bloc(point ,"Standard","Sur mesure", longueur, "Refend")
			entite = bloc.entities
			haut_maxi = (longueur * Math.tan(pente*Math::PI/180)) / 2.0 
			if (haut_maxi >= $haut_pmb)
				haut_maxi = $haut_pmb
			else
				decalage = (haut_maxi / Math.tan(pente*Math::PI/180))
				pt = []
				pt[0] = Geom::Point3d.new(point.x, 0, haut_maxi.mm + point.z)
				pt[1] = Geom::Point3d.new(point.x, 0, $haut_pmb.mm + point.z)
				pt[2] = Geom::Point3d.new(point.x + longueur.mm, 0, $haut_pmb.mm + point.z)
				pt[3] = Geom::Point3d.new(point.x + longueur.mm, 0, haut_maxi.mm + point.z)
				face = entite.add_face pt
				line = entite.add_line pt[0], pt[3]
				face.followme line 
			end

			pt = []
			pt[0] = Geom::Point3d.new(point.x, 0, point.z)
			pt[1] = Geom::Point3d.new(point.x, 0, haut_maxi.mm+point.z)
			pt[2] = Geom::Point3d.new(point.x + decalage.mm, 0, haut_maxi.mm+point.z)
			face = entite.add_face pt
			pt[3] = Geom::Point3d.new(point.x + @offset_chanfrein.mm, 0, point.z + $haut_pmb.mm - @pmb.chanfrein.mm)
			pt[4] = Geom::Point3d.new(point.x + longueur.mm - @offset_chanfrein.mm, 0, point.z + $haut_pmb.mm - @pmb.chanfrein.mm)
			line_chanfrein = entite.add_line pt[3], pt[4] if((self.style == "Ext") && (haut_maxi >= $haut_pmb))
			line = entite.add_line pt[0], pt[2]  
			face.followme line

			pt = []
			pt[0] = Geom::Point3d.new(longueur.mm + point.x, 0, point.z);
			pt[1] = Geom::Point3d.new(longueur.mm + point.x, 0, haut_maxi.mm+point.z);
			pt[2] = Geom::Point3d.new((longueur-decalage).mm + point.x, 0, haut_maxi.mm+point.z);
			face = entite.add_face pt 
			line = entite.add_line pt[0], pt[2]
			face.followme line
			return longueur_bloc.round, bloc
    end
    
    def calculs_parametres_fenetres_pignon(mur, coord)
        $nom_fenetres_pignon = []
        $montage_fenetres_pignon = []
        $x_debut_pignon = []
        $x_fin_pignon = []
        $z_maxi_pignon = []
        $z_mini_pignon = []
        $z_mini_classes_pignon = []
	    if !(mur.objets_classes_pignon.empty?)
	      parametres = mur.objets_classes_pignon
	      UI.messagebox("parametres = #{mur.objets_classes_pignon.inspect}") if $DEBUG
	      parametres.each do |z|
	        $nom_fenetres_pignon.push(z.nom)
	        $montage_fenetres_pignon.push(z.montage)
	        $x_debut_pignon.push(z.x_debut)
	        $x_fin_pignon.push(z.x_fin)
	        $z_maxi_pignon.push(z.z_max.mm)
	        $z_mini_pignon.push(z.z_min.mm)
	      end
		  end 
		  $z_mini_pignon.push((mur.hauteur-$haut_pmb).mm) if ($z_mini_pignon.empty?)
	    $z_maxi_pignon.push(mur.hauteur.mm) if ($z_maxi_pignon.empty?)
	    $x_fin_pignon.push(mur.longueur) if($x_fin_pignon.empty?)

      $z_mini_classes_pignon = Array.new($z_mini_pignon.sort)
      $z_min_min_pignon = $z_mini_classes_pignon[0]
      $z_min_max_pignon = $z_mini_classes_pignon[-1]
      $z_mini_classes_pignon.push(mur.hauteur.mm)

      $z_maxi_classes_pignon = Array.new($z_maxi_pignon.sort)
      $z_max_pignon = $z_maxi_classes_pignon[-1]
      
      $x_fin_pignon.push(mur.longueur)
      $minimum_pignon = $z_mini_pignon.sort[0]
      $maximum_pignon = $z_mini_pignon.sort[-1]
      return 
    end
 
    def recherche_zone1(mur, coord)
    	z = coord.z
    	x = coord.x
      zone = nil
      indice = nil
      if(z < $z_min_max_pignon)||(z > $z_max_pignon)||(z == mur.hauteur.mm)
        zone = "zone_A1"
      else
        x_debut = mur.longueur.mm
        mur.objets_classes_pignon.each do |fen|
          if(x >= fen.x_debut.mm)
            if((objets_classes_pignon.index(fen)+1) == (objets_classes_pignon.length))
              zone = "zone_D1"
            end
          elsif(z >= fen.z_min.mm)
              if(fen.x_debut.mm < x_debut)
                $indice_suivant = objets_classes_pignon.index(fen)
                x_debut = fen.x_debut.mm
                if (x < $x_debut_pignon[0].mm)
                  zone = "zone_C1"
                else
                  zone = "zone_E1"
                end
              end
          elsif(x_debut == mur.longueur.mm)
            zone = "zone_D1"
          end
        end
      end
      return zone
    end
    
    def determiner_zone_mur1(mur,coord)
      $zone_A1 = $zone_B1 = $zone_C1 = $zone_D1 = $zone_E1 = nil
      zone = recherche_zone1(mur,coord)
      $zone_A1 = true if (zone == "zone_A1")
      $zone_B1 = true if (zone == "zone_B1")
      $zone_C1 = true if (zone == "zone_C1")
      $zone_D1 = true if (zone == "zone_D1")
      $zone_E1 = true if (zone == "zone_E1")
    end

    def draw_Zone_A1(entite, nb_bloc_rang, pair, coord)
      nb_bloc = nb_bloc_rang
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
      return entite, coord
    end
    
    def calcul_zone_C1(coord, rang_pair)
      $fenetre_active = objets_classes_pignon[$indice_suivant]
      montage_suivant = $fenetre_active.montage
      montage_mur = self.montage
      if (montage_mur =~/^\S1$/)
      	pair = rang_pair # rien ne change
      else
      	pair = !rang_pair # inversion de la parité
      end
      $origine_x_fin = $fenetre_active.x_fin
      x_fin = $fenetre_active.x_debut
      puts($fenetre_active.inspect) if $DEBUG_ZONE_C1
      puts("x_fin = #{x_fin}") if $DEBUG_ZONE_C1
      
      if ((((montage_suivant == "A") || (montage_suivant == "C")) &&  pair) ||
      		(((montage_suivant == "B") || (montage_suivant == "D")) && !pair))
    		x_fin -= $long_pmb_demi
    	else
    		x_fin -= $long_pmb
    	end
    	
      x_debut = coord.x.to_mm.to_i
      puts("x_debut = #{x_debut}") if $DEBUG_ZONE_C1
    	long_C1 = (x_fin - x_debut).round
    	if long_C1 < 0
    		long_C1 = 0
    	end
      
      nb_bloc_C1 = (long_C1/$long_pmb).to_int
      ecart1 = (long_C1 % $long_pmb).round
      puts("ecart1 = #{ecart1}\n\n") if $DEBUG_ZONE_C1
      if (ecart1 <= $long_pmb_demi) && (ecart1 != 0)  
      	ecart1 += $long_pmb
      	nb_bloc_C1 -= 1
      end if (nb_bloc_C1 > 0) 
      puts("pair = #{pair}") if $DEBUG_ZONE_C1
      puts("long_C1 = #{long_C1.to_f}") if $DEBUG_ZONE_C1
      puts("montage_suivant = #{montage_suivant}") if $DEBUG_ZONE_C1
      puts("nb_bloc_C1 = #{nb_bloc_C1}")  if $DEBUG_ZONE_C1
      return nb_bloc_C1, ecart1
    end
    
    def calcul_zone_D1(coord, rang_pair, long_restante)
      montage_fenetre = $fenetre_active.montage
      montage_mur = self.montage
      if (montage_mur =~/^\S1$/)
      	pair = rang_pair # rien ne change
      else
      	pair = !rang_pair # inversion de la parité
      end
      x_debut = $fenetre_active.x_fin
      UI.messagebox($fenetre_active.inspect) if $DEBUG_FENETRE

      if ((((montage_fenetre == "A") || (montage_fenetre == "D")) &&  pair) ||
      		(((montage_fenetre == "B") || (montage_fenetre == "C")) && !pair))
    		x_debut += $long_pmb_demi
    	else
    		x_debut += $long_pmb
    	end
      
      x_fin = long_restante
      coord.x = x_debut.mm
      long_D = (x_fin - x_debut).round
      if long_D < 0
      	long_D = 0
      end
      puts("long_restante = #{long_restante}") if $DEBUG_ZONE_D1                               
      nb_bloc_D = ((long_D/$long_pmb)).to_int
      puts("nb_bloc_D = #{nb_bloc_D}") if $DEBUG_ZONE_D1
      ecart = (long_D % $long_pmb).round 
      puts("ecart = #{ecart}") if $DEBUG_ZONE_D1
      if (ecart <= $long_pmb_demi) && (ecart != 0) && (nb_bloc_D != 0)
      	ecart += $long_pmb
      	nb_bloc_D -= 1
      end 
      puts("x_debut = #{x_debut}") if $DEBUG_ZONE_D1
      puts("x_fin = #{x_fin}") if $DEBUG_ZONE_D1
      puts("long_D = #{long_D}") if $DEBUG_ZONE_D1
      puts("nb_bloc_D = #{nb_bloc_D}") if $DEBUG_ZONE_D1
      puts("ecart = #{ecart}") if $DEBUG_ZONE_D1
      puts("parité paire = #{pair}") if $DEBUG_ZONE_D1
      puts if $DEBUG_ZONE_D1
      return nb_bloc_D, ecart, coord
    end
    
    def calcul_zone_E1(coord, rang_pair) 
      fenetre_precedente = $fenetre_active
      puts("fenetre_precedente = #{fenetre_precedente.inspect}\n\n") if $DEBUG_ZONE_E1
      montage_precedent = fenetre_precedente.montage
      montage_mur = self.montage
      if (montage_mur =~/^\S1$/)
      	pair = rang_pair # rien ne change
      else
      	pair = !rang_pair # inversion de la parité
      end
      x_debut = fenetre_precedente.x_fin
      $fenetre_active = objets_classes_pignon[$indice_suivant]
      puts("fenetre_active = #{$fenetre_active.inspect}\n\n") if $DEBUG_ZONE_E1
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

      puts("x_debut = #{x_debut}") if $DEBUG_ZONE_E1
      puts("x_fin = #{x_fin}") if $DEBUG_ZONE_E1
      
      if ((((montage_precedent == "A")||(montage_precedent == "D")) &&  pair) ||\
          (((montage_precedent == "B")||(montage_precedent == "C")) && !pair))
        x_debut += $long_pmb_demi 
      else
      	x_debut += $long_pmb
      end
      
      if ((((montage_suivant == "A")||(montage_suivant == "C")) &&  pair) ||\
          (((montage_suivant == "B")||(montage_suivant == "D")) && !pair))
        x_fin -= $long_pmb_demi 
      else
      	x_fin -= $long_pmb
      end
      long_E = (x_fin - x_debut).round
      if long_E < 0
      	long_E = 0
      end
      coord.x = x_debut.mm
      
      puts("pair = #{pair}") if $DEBUG_ZONE_E1
      puts("x_debut = #{x_debut}") if $DEBUG_ZONE_E1
      puts("x_fin = #{x_fin}") if $DEBUG_ZONE_E1
      puts("x = #{coord.x}") if $DEBUG_ZONE_E1
      puts("long_E = #{long_E}") if $DEBUG_ZONE_E1
      puts("montage_precedent = #{montage_precedent}") if $DEBUG_ZONE_E1
      puts("montage_actuel = #{montage_suivant}") if $DEBUG_ZONE_E1
      #UI.messagebox("Stop !") if $DEBUG_ZONE_E

      nb_bloc_E = (long_E/$long_pmb).to_int
      puts("nb_bloc_E = #{nb_bloc_E}") if $DEBUG_ZONE_E1
      ecart = (long_E%$long_pmb).round
      puts("ecart = #{ecart}") if $DEBUG_ZONE_E1
      if (ecart <= $long_pmb_demi) && (ecart != 0) && (nb_bloc_E != 0)
      	ecart += $long_pmb
      	nb_bloc_E -= 1
      end 
      return nb_bloc_E, ecart, coord
    end
    
    def draw_Zone_C1(entite, coord, pair)
  		nb_bloc, difference = calcul_zone_C1(coord, pair)
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

    def draw_Zone_D1(entite, coord, pair, long_restante)
  		nb_bloc, difference, coord = calcul_zone_D1(coord, pair, long_restante)
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
      return entite, coord
		end

    def draw_Zone_E1(entite, coord, pair)
      nb_bloc, difference, coord = calcul_zone_E1(coord, pair)
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

		def dessine_pignon()
			difference = 0 
			k = 0
			pignon = []
			@pmb = Bloc_PMB.new(remplir_options(
			  %w[style layer],
			  'calque'  => self.calque,
			  'style'  => self.style,
			  'largeur'=> self.largeur
			))
			decalage = $haut_pmb / Math.tan(pente*Math::PI/180)
			@offset_chanfrein = ($haut_pmb - 10) / Math.tan(pente*Math::PI/180)
			pt_offset = Geom::Point3d.new()
			pt_orig = Geom::Point3d.new()
			pt_orig.z = self.hauteur.mm
			calculs_parametres_fenetres_pignon(self, pt_orig)
			
			case (type_toit)
			when "2 pentes /\\"
				@long_pignon = self.longueur
				nb_rangs = (((@long_pignon/2.0) * Math.tan(pente*Math::PI/180))/($haut_pmb))+1
			when "1 pente __\\"
				@long_pignon = self.longueur
				nb_rangs = (@long_pignon * Math.tan(pente*Math::PI/180))/$haut_pmb
			when "1 pente /__"
				long_pignon = self.longueur
				nb_rangs = (@long_pignon * Math.tan(pente*Math::PI/180))/$haut_pmb
			end
			difference_1 = difference_2 = 0	
			for rang in 1...(nb_rangs)
        pair = false
        if (self.montage =~/^\S1$/)
          pair = true if !(rang%2!=0)
        elsif (self.montage =~/^\S2$/)
          pair = true if (rang%2!=0)
        end
				
				if pair
					offset = self.largeur
				else
					offset = self.largeur + $long_pmb_demi
				end
				case (type_toit)
				when "2 pentes /\\"
					if (@long_pignon >= (4 * $long_pmb_demi - 2 * decalage))&&(@long_pignon >= difference_1 + difference_2)
						@long_pignon = @long_pignon.to_int
						nb_bloc = ((@long_pignon - offset + k*decalage)/ $long_pmb).truncate
						difference_1 = ((@long_pignon - offset + k*decalage) % $long_pmb).round
						puts("long_pignon = #{@long_pignon}") if $DEBUG_PIGNON
						puts("offset = #{offset}") if $DEBUG_PIGNON
						puts("nb_bloc = #{nb_bloc}") if $DEBUG_PIGNON
						puts("difference = #{difference_1}") if $DEBUG_PIGNON
						puts("rang = #{rang}") if $DEBUG_PIGNON
						puts("offset - k*decalage = #{offset - k*decalage}") if $DEBUG_PIGNON
						if (difference_1 <= ($long_pmb_demi))
							difference_1 += $long_pmb
							nb_bloc -= 1
						end 
						difference_2 = $long_pmb + offset - k*decalage
						while (difference_2 >= $long_pmb)
							difference_2 -= $long_pmb
							nb_bloc += 1
						end
						while (difference_2 <= $long_pmb_demi)
							difference_2 += $long_pmb
							nb_bloc -= 1
						end
						puts("difference_2 = #{difference_2}") if $DEBUG_PIGNON
						puts("nb_bloc = #{nb_bloc}") if $DEBUG_PIGNON
						puts("-------------------------") if $DEBUG_PIGNON
						# premier bloc
						long, groupe = creer_bloc_bord_pignon_gauche(pt_orig, difference_1, decalage)
            groupe.name = long.to_s + ";" + largeur.to_s + ";" + "bloc bord pignon gauche" + ";" +style
						pignon.push(groupe)
						pt_orig.x += long.mm
						nb_bloc -= 1					
						 
						
     		    determiner_zone_mur1(self,pt_orig)

		        if ($zone_A1)
		    			# Construction de la rangée de (N-1) premier bloc PMB
		    			pignon, pt_orig = draw_Zone_A1(pignon, nb_bloc, pair, pt_orig )
		    		elsif ($zone_B1)
		    			# Pose de la ceinture (linteau)
		    			pignon, pt_orig = draw_Zone_B1(pignon, @long_pignon, self.largeur, pair, montage, pt_orig, difference_2)
		    		elsif ($zone_C1)
		    			pignon, pt_orig = draw_Zone_C1(pignon, pt_orig, pair)
		    			determiner_zone_mur1(self,pt_orig)
		          while($zone_E1)
		          	#UI.messagebox("Zone E1")
		            pignon, pt_orig = draw_Zone_E1(pignon, pt_orig, pair)
		            determiner_zone_mur1(self,pt_orig)
		          end
		          if ($zone_D1)
		            pignon, pt_orig = draw_Zone_D1(pignon, pt_orig, pair, @long_pignon + pt_offset.x.to_mm.to_i + k*decalage - difference_2)
		          end
		    		end
						# denier bloc
						long, groupe = creer_bloc_bord_pignon_droit(pt_orig , difference_2, decalage)
            groupe.name = long.to_s + ";" + largeur.to_s + ";" + "bloc bord pignon droite" + ";" +style
						pignon.push(groupe)
						pt_orig.x += long.mm
					else
						difference = @long_pignon.round
						break if (difference == 0)
						long, groupe = creer_bloc_haut_pignon(pt_orig, difference, decalage)
            groupe.name = long.to_s + ";" + largeur.to_s + ";" + "bloc haut pignon" + ";" +style
						pignon.push(groupe)
					end
					k += 1
					@long_pignon -= 2*decalage
					pt_orig.x = pt_offset.x + k*decalage.mm
					pt_orig.z += $haut_pmb.mm 
				when "1 pente /__"
					if ((long_pignon >= (difference_1 + $long_pmb_demi + self.largeur)) && ((montage =~ /^A\w$/ && !pair)||(montage =~ /^B\w$/ && pair)))||
						((long_pignon >= (difference_1 + self.largeur)) && !((montage =~ /^A\w$/ && !pair)||(montage =~ /^B\w$/ && pair)))
						long_pignon = long_pignon.to_int
						if (montage =~ /^A\w$/ && !pair)||(montage =~ /^B\w$/ && pair)
							nb_bloc = ((long_pignon - $long_pmb_demi - self.largeur) / $long_pmb).truncate
							difference_1 = ((long_pignon - $long_pmb_demi - self.largeur) % $long_pmb).round
						else
							nb_bloc = ((long_pignon - self.largeur) / $long_pmb).truncate
							difference_1 = ((long_pignon - self.largeur) % $long_pmb).round								 
						end
						if (difference_1 <= ($long_pmb_demi))
							difference_1 += $long_pmb
							nb_bloc -= 1
						end 
						# premier bloc
						long, groupe = creer_bloc_bord_pignon_gauche(pt_orig, difference_1, decalage)
            groupe.name = long.to_s + ";" + largeur.to_s + ";" + "bloc bord pignon gauche" + ";" +style
						pignon.push(groupe)
						pt_orig.x += long.mm
						# blocs suivants
						for i in 1..(nb_bloc)
							long, groupe = ajoute_bloc(pt_orig , "Standard")
							pignon.push(groupe)
							pt_orig.x += long.mm
						end
						# denier bloc s'il y a lieu
		    		if (montage =~ /^A\w$/ && !pair)||(montage =~ /^B\w$/ && pair)
		    			long, element = ajoute_bloc(pt_orig,"Angle", "Droite")
		    			pignon.push(element)
		    		end
					else
						difference = long_pignon 
						break if (difference == 0)
						long, groupe = creer_bloc_bord_pignon_gauche(pt_orig, difference, decalage)
            groupe.name = long.to_s + ";" + largeur.to_s + ";" + "bloc bord pignon gauche" + ";" +style
						pignon.push(groupe)
					end
					k += 1
					pt_orig.x += long.mm
					long_pignon -= decalage
					pt_orig.x = pt_offset.x + k*decalage.mm
					pt_orig.z += $haut_pmb.mm 
				when "1 pente __\\"
					if ((long_pignon >= (difference_1 + $long_pmb_demi + self.largeur)) && ((montage =~ /^A\w$/ && !pair)||(montage =~ /^B\w$/ && pair)))||
						((long_pignon >= (difference_1 + self.largeur)) && !((montage =~ /^A\w$/ && !pair)||(montage =~ /^B\w$/ && pair)))
						long_pignon = long_pignon.to_int
						if !(pair)
							nb_bloc = ((long_pignon - $long_pmb_demi - self.largeur) / $long_pmb).truncate
							difference_1 = ((long_pignon - $long_pmb_demi - self.largeur) % $long_pmb).round
						else
							nb_bloc = ((long_pignon - self.largeur) / $long_pmb).truncate
							difference_1 = ((long_pignon - self.largeur) % $long_pmb).round								 
						end
						if (difference_1 <= ($long_pmb_demi))
							difference_1 += $long_pmb
							nb_bloc -= 1
						end 
						# premier bloc s'il y a lieu
						if ! pair
							long, groupe = ajoute_bloc(pt_orig,"Angle", "Gauche")
							pignon.push(groupe)
							pt_orig.x += long.mm
							#nb_bloc -= 1
						else
							pt_orig.x += self.largeur.mm
						end
						# blocs suivants
						for i in 1..(nb_bloc)
							long, groupe = ajoute_bloc(pt_orig , "Standard")
							pignon.push(groupe)
							pt_orig.x += long.mm
						end
						# denier bloc
	    			long, element = creer_bloc_bord_pignon_droit(pt_orig , difference_1, decalage)
            element.name = long.to_s + ";" + largeur.to_s + ";" + "bloc bord pignon droite" + ";" +style
	    			pignon.push(element)
	    			pt_orig.x += long.mm
					else
						difference = long_pignon 
						break if (difference == 0)
						long, groupe = creer_bloc_bord_pignon_droit(pt_orig, difference, decalage)
            groupe.name = long.to_s + ";" + largeur.to_s + ";" + "bloc bord pignon gauche" + ";" +style
						pignon.push(groupe)
						pt_orig.x += long.mm
					end
					k += 1
					long_pignon -= decalage
					pt_orig.x = pt_offset.x
					pt_orig.z += $haut_pmb.mm 
					
				end
			end
      # recherche des groupes
      # -----------------------------
      liste_groupe = "" 
      liste_composant = ""
      liste_groupes = Array.new() 
      liste_composants = Array.new()
      pignon.each do |groupe|
        if groupe.typename == "Group"
          liste_groupe += (nom + ";" + groupe.name+ "-")
        end
        if groupe.typename == "ComponentInstance"
          liste_composant += (nom + ";" + groupe.name+ "-")
        end
      end
      liste_g = liste_groupe.split("-")
      i = 0
      liste_g.each {|str| liste_groupes[i]=str.split(";"); i+=1}

      liste_c = liste_composant.split("-")
      i = 0
      liste_c.each {|str| liste_composants[i]=str.split(";"); i+=1}
      
      self.liste_composant = liste_groupes + liste_composants
      liste_groupes = liste_composants = nil
			
			modele = Sketchup.active_model.entities
			partie_pignon = modele.add_group(pignon)
			partie_pignon.name = "pignon"
			sauve_options_dessin(partie_pignon)
			return partie_pignon
		end
	end
end