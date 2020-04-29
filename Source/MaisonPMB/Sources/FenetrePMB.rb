 module PMB
  #----------------------------- F E N E T R E -----------------------
  # A window has studs, headers, cripples and a sill.
  # options:
  #-------------------------------------------------------------------
  class Fenetre < Ouverture_PMB
  
    def initialize(options = {})
      defaut_options_fenetre = { 
        'element'         => 'Fenetre',
        'nom'             => '',
        'x_debut'         => 0,
        'x_fin'           => 0,
        'justification'   => 'Gauche',
        'hauteur_linteau' => 2295, #2210
        'longueur_linteau'=> 0,
        'center_offset'   => 0,
        'largeur'         => 900,
        'hauteur'         => 1360,
        'nb_rangs'        => 0,
        'liste_composant'	=> "",
        'z_max'           => 0,
        'z_min'           => 0,
        'montage'         => nil,
        'index'						=> nil,
        'calque'          => 'Fenetre',
        'nb_demi_bloc_L1' => 0,
      }
      @nb_demi_bloc_L1 = 0
      @nb_bloc_std_L1 = 0
      @nb_total_demi_bloc = 0
      @nb_demi_bloc_L1 =0
      applique_options_globales(defaut_options_fenetre)
      defaut_options_fenetre.update(options)
      super(defaut_options_fenetre)
      if (self.nom.length == 0)
        self.nom = Base_PMB.nom_unique("fenetre")
      end
    end
    
    def options_Fenetres(obj = self)
      proprietes_fenetre = [
        # prompt, attr_name, enums
        [ "Justification Fenêtre", "justification", "Gauche|Centre|Droite" ],
        [ "Hauteur du linteau", "hauteur_linteau", nil ],
        [ "largeur de la fenêtre", "largeur", nil ],
        [ "Hauteur de la fenêtre", "hauteur", nil ],
        [ "Montage de la fenêtre", "montage", "A|Aa|Ab|Ac|B|Ba|Bb|Bc|C|Ca|Cb|Cc|D|Da|Db|Dc|E|Ea|Eb|Ec|F|Fa|Fb|Fc|G|Ga|Gb|Gc|H|Ha|Hb|Hc|I|Ia|Ib|Ic|J|Ja|Jb|Jc|K|Ka|Kb|Kc|L|La|Lb|Lc"],
      ].freeze
      results = affiche_dialogue("Propriétés des fenêtres", obj, proprietes_fenetre)
      obj.hauteur = corrige_hauteur(obj.hauteur) if((obj.hauteur.to_f % $haut_pmb)!=0)
      obj.hauteur_linteau = corrige_hauteur(obj.hauteur_linteau) if((obj.hauteur_linteau.to_f % $haut_pmb)!=0)
      obj.x_debut = obj.center_offset - obj.largeur/2
      obj.x_fin = obj.center_offset + obj.largeur/2
      obj.nb_rangs, obj.z_max, obj.z_min  = calcul_nb_rang()
      return false if not results
	  return results
    end
      
    # création d'une fenêtre utilisant les propriétés stockées dans le dessin'
    def self.creation_pour_dessin(group)
        fenetre = Fenetre.new()
        fenetre.recupere_option_dessin(group)
        return fenetre
    end
    
    def calcul_nb_rang
      bloc_pmb = Bloc_PMB.new
      nombre = (self.hauteur/bloc_pmb.hauteur).round + 1
      hauteur_montage = (nombre) * bloc_pmb.hauteur
      z_max = self.hauteur_linteau
      z_min = (z_max - hauteur_montage)
      #puts z_min.to_s + ", " + z_max.to_s + ", "
      return nombre, z_max, z_min
    end
    
    def dessine_objet(mur, coord, obj = self)
      modele = Sketchup.active_model.entities
      point=Geom::Point3d.new
      point=point.set!(coord)
      rang_obj = []
      x1= x_debut
      puts("montage de la porte #{obj.montage}") if $DEBUG
      parite_z_max = (z_max / $haut_pmb) % 2 == 0
      if (mur.montage =~/^\S1$/)
	      case (parite_z_max)
	      when false
		      if(montage == "B")||(montage == "D")||(montage == "E")||(montage == "G")||
		      	(montage == "Aa")||(montage == "Ca")||(montage == "Ea")||(montage == "Ga")||(montage == "Ia")||(montage == "Ka")
		        x11 = x1 - $long_pmb
		        x11 = x1 - $long_pmb_demi - mur.largeur if (montage == "E") || (montage == "G")||(montage == "Ea") || (montage == "Ga")
		        x12 = x1 - $long_pmb_demi
		      else
		        x11 = x1 - $long_pmb_demi 
		        x11 = x1 - $long_pmb if montage=="L"||montage=="J"
		        x11 = x1 - $long_pmb_demi - mur.largeur if montage=="H"||montage=="Ha"||(montage == "F") ||(montage == "Fa")
		        x12 = x1 - $long_pmb 
		        x12 = x1 - $long_pmb_demi if montage=="J"||montage=="H"||montage=="Ha"||(montage == "F") ||(montage == "Fa")||montage=="L" 
		      end
		    when true
		      if(montage == "A")||(montage == "C")||(montage == "E")||(montage == "G")||(montage == "I")||(montage == "K")||
		      	(montage == "Aa")||(montage == "Ca")||(montage == "Ea")||(montage == "Ga")||(montage == "Ia")||(montage == "Ka")
		        x11 = x1 - $long_pmb_demi
		        x12 = x1 - $long_pmb
		        x12 = x1 - $long_pmb_demi - mur.largeur if (montage == "E") || (montage == "G")||(montage == "Ea") || (montage == "Ga")
		      else
		        x11 = x1 - $long_pmb
		        x11 = x1 - $long_pmb_demi if (montage == "F") ||(montage == "Fa")||montage=="H"||montage=="Ha"
		        x12 = x1 - $long_pmb_demi
		      end
		    end
		    x11 = x12 = x1 if (montage =~/^\Sb$/)||(montage =~/^\Sc$/)
		  else
	      case (parite_z_max)
	      when true
		      if(montage == "B")||(montage == "D")||(montage == "E")||(montage == "G")||
		      	(montage == "Aa")||(montage == "Ca")||(montage == "Ea")||(montage == "Ga")||(montage == "Ia")||(montage == "Ka")
		        x11 = x1 - $long_pmb
		        x11 = x1 - $long_pmb_demi - mur.largeur if (montage == "E") || (montage == "G")||(montage == "Ea") || (montage == "Ga")
		        x12 = x1 - $long_pmb_demi
		      else
		        x11 = x1 - $long_pmb_demi 
		        x11 = x1 - $long_pmb if montage=="L"||montage=="J"
		        x11 = x1 - $long_pmb_demi - mur.largeur if montage=="H"||montage=="Ha"||(montage == "F") ||(montage == "Fa")
		        x12 = x1 - $long_pmb 
		        x12 = x1 - $long_pmb_demi if montage=="J"||montage=="H"||montage=="Ha"||(montage == "F") ||(montage == "Fa")||montage=="L" 
		      end
		    when false
		      if(montage == "A")||(montage == "C")||(montage == "E")||(montage == "G")||(montage == "I")||(montage == "K")||
		      	(montage == "Aa")||(montage == "Ca")||(montage == "Ea")||(montage == "Ga")||(montage == "Ia")||(montage == "Ka")
		        x11 = x1 - $long_pmb_demi
		        x12 = x1 - $long_pmb
		        x12 = x1 - $long_pmb_demi - mur.largeur if (montage == "E") || (montage == "G")||(montage == "Ea") || (montage == "Ga")
		      else
		        x11 = x1 - $long_pmb
		        x11 = x1 - $long_pmb_demi if (montage == "F") ||(montage == "Fa")||montage=="H"||montage=="Ha"
		        x12 = x1 - $long_pmb_demi
		      end
		    end
		    x11 = x12 = x1 if (montage =~/^\Sb$/)||(montage =~/^\Sc$/)
		  end 
      x2 = x_fin
      point.z = z_max.mm
      # Linteau de tête
      if (longueur_linteau % $long_pmb == 0)
      	taille = longueur_linteau + 2*$long_pmb if (montage=="Aa")||(montage=="Ca")
      	taille = longueur_linteau + $long_pmb if (montage=="Ba")||(montage=="Da")
      	taille = longueur_linteau + 3*$long_pmb_demi + mur.largeur if (montage=="Ea")||(montage=="Ga")
      	taille = longueur_linteau + $long_pmb if (montage=="Fa")||(montage=="Ha")
      else
      	taille = longueur_linteau + 3*$long_pmb_demi if (montage =~/^\S$/)||(montage =~/^\Sa$/)
      	taille = longueur_linteau + $long_pmb + mur.largeur if (montage=="Ea")||(montage=="Ga")
      end
      taille = largeur + 2*$long_pmb if (montage=="A") 
      taille = largeur + $long_pmb if (montage=="B")||(montage=="F")||(montage=="J")
      taille = largeur + $long_pmb + mur.largeur if (montage=="G")||(montage=="L")
      taille = largeur + 3*$long_pmb_demi if (montage=="C")||(montage=="D")||(montage=="H")||(montage=="K")
      taille = largeur + 3*$long_pmb_demi + mur.largeur if (montage=="E")||(montage=="I")
      taille = 0 if (montage =~/^\Sb$/)||(montage =~/^\Sc$/)
      
      point.x = x12.mm
     
      long, bloc = mur.ajoute_bloc(point,"Standard",nil,nil,"Sur mesure", taille) if (taille !=0) if !((montage =~/^\Sb$/)||(montage =~/^\Sc$/))
      bloc.name = long.to_i.to_s+ ";" + mur.largeur.to_s + ";" + "Linteau fenetre" + ";"+ mur.style if point.z==z_max.mm if bloc
      
      rang_obj.push(bloc) if( taille !=0) if !((montage =~/^\Sb$/)||(montage =~/^\Sc$/))
      point.z -= $haut_pmb.mm
      
      # montage de l'ouverture
      for rang in 1..(nb_rangs-1)
      	if (mur.montage =~/^\S1$/)
	      	if !parite_z_max
		        if (rang%2!=0)
		          taille_1 = "Standard" if (montage=="B")||(montage == "D")||(montage=="J")||(montage == "L")
		          taille_1 = "Angle" if (montage=="E")||(montage=="F")||(montage == "G")||(montage == "H")
		          taille_1 = "Demi" if (montage=="A")||(montage == "C")||(montage=="I")||(montage=="K")
		          taille_1 = "Standard" if (montage=="Ba")||(montage == "Da")||(montage=="Ja")||(montage == "La")
		          taille_1 = "Angle" if (montage=="Ea")||(montage=="Fa")||(montage == "Ga")||(montage == "Ha")
		          taille_1 = "Demi" if (montage=="Aa")||(montage == "Ca")||(montage=="Ia")||(montage=="Ka")
		          taille_2 = "Standard" if (montage=="B")||(montage == "C")||(montage=="E")||(montage=="F")
		          taille_2 = "Demi" if (montage=="A")||(montage == "D")||(montage == "H")||(montage == "G")||(montage=="I")||(montage=="L")
		          taille_2 = "Angle" if (montage=="J")||(montage=="K")
		          taille_2 = "Standard" if (montage=="Bb")||(montage == "Cb")||(montage=="Eb")||(montage=="Fb")
		          taille_2 = "Demi" if (montage=="Ab")||(montage == "Db")||(montage == "Hb")||(montage == "Gb")||(montage=="Ib")||(montage=="Lb")
		          taille_2 = "Angle" if (montage=="Jb")||(montage=="Kb")
		          point.x = x11.mm
		        else
		          taille_1 = "Demi" if (montage=="B")||(montage == "D")||(montage == "E")||(montage == "F")||(montage=="J")||(montage == "G")||(montage == "H")||(montage=="L")
		          taille_1 = "Standard" if (montage=="A")||(montage == "C")||(montage=="I")||(montage=="K")
		          taille_1 = "Demi" if (montage=="Ba")||(montage == "Da")||(montage == "Ea")||(montage == "Fa")||(montage=="Ja")||(montage == "Ga")||(montage == "Ha")||(montage=="La")
		          taille_1 = "Standard" if (montage=="Aa")||(montage == "Ca")||(montage=="Ia")||(montage=="Ka")
		          taille_2 = "Demi" if (montage=="B")||(montage == "C")||(montage=="E")||(montage=="F")||(montage=="I")||(montage=="J")||(montage=="K")
		          taille_2 = "Standard" if (montage=="A")||(montage == "D")||(montage == "G")||(montage == "H")
		          taille_2 = "Angle" if (montage=="I")||(montage=="L")
		          taille_2 = "Demi" if (montage=="Bb")||(montage == "Cb")||(montage=="Eb")||(montage=="Fb")||(montage=="Ib")||(montage=="Jb")||(montage=="Kb")
		          taille_2 = "Standard" if (montage=="Ab")||(montage == "Db")||(montage == "Gb")||(montage == "Hb")
		          taille_2 = "Angle" if (montage=="Ib")||(montage=="Lb")
		          point.x = x12.mm
		        end
	        else        	
		        if (rang%2!=0)
		          taille_1 = "Standard" if (montage=="B")||(montage == "D")||(montage=="J")||(montage == "L")
		          taille_1 = "Angle" if (montage == "H")
		          taille_1 = "Demi" if (montage=="A")||(montage == "C")||(montage=="E")||(montage=="F")||(montage == "G")||(montage=="I")||(montage=="K")
		          taille_1 = "Standard" if (montage=="Ba")||(montage == "Da")||(montage=="Ja")||(montage == "La")
		          taille_1 = "Angle" if (montage == "Ha")
		          taille_1 = "Demi" if (montage=="Aa")||(montage == "Ca")||(montage=="Ea")||(montage=="Fa")||(montage == "Ga")||(montage=="Ia")||(montage=="Ka")
		          taille_2 = "Standard" if (montage=="B")||(montage == "C")||(montage == "G")
		          taille_2 = "Demi" if (montage=="A")||(montage == "D")||(montage=="E")||(montage=="F")||(montage == "H")||(montage=="I")||(montage=="L")
		          taille_2 = "Angle" if (montage=="J")||(montage=="K")
		          taille_2 = "Standard" if (montage=="Bb")||(montage == "Cb")||(montage == "Gb")
		          taille_2 = "Demi" if (montage=="Ab")||(montage == "Db")||(montage=="Eb")||(montage=="Fb")||(montage == "Hb")||(montage=="Ib")||(montage=="Lb")
		          taille_2 = "Angle" if (montage=="Jb")||(montage=="Kb")
		          point.x = x11.mm
		        else
		          taille_1 = "Demi" if (montage=="B")||(montage == "D")||(montage=="J")||(montage == "H")||(montage=="L")
		          taille_1 = "Standard" if (montage=="A")||(montage == "C")||(montage=="I")||(montage=="K")
		          taille_1 = "Angle" if (montage == "E")||(montage == "F")||(montage == "G")
		          taille_1 = "Demi" if (montage=="Ba")||(montage == "Da")||(montage=="Ja")||(montage == "Ha")||(montage=="La")
		          taille_1 = "Standard" if (montage=="Aa")||(montage == "Ca")||(montage=="Ia")||(montage=="Ka")
		          taille_1 = "Angle" if (montage == "Ea")||(montage == "Fa")||(montage == "Ga")
		          taille_2 = "Demi" if (montage=="B")||(montage == "C")||(montage == "G")||(montage=="I")||(montage=="J")||(montage=="K")
		          taille_2 = "Standard" if (montage=="A")||(montage == "D")||(montage=="E")||(montage=="F")||(montage == "H")
		          taille_2 = "Angle" if (montage=="I")||(montage=="L")
		          taille_2 = "Demi" if (montage=="Bb")||(montage == "Cb")||(montage == "Gb")||(montage=="Ib")||(montage=="Jb")||(montage=="Kb")
		          taille_2 = "Standard" if (montage=="Ab")||(montage == "Db")||(montage=="Eb")||(montage=="Fb")||(montage == "Hb")
		          taille_2 = "Angle" if (montage=="Ib")||(montage=="Lb")
		          point.x = x12.mm
		        end
	      	end
      	else
	      	if !parite_z_max
		        if !(rang%2!=0)
		          taille_1 = "Standard" if (montage=="A")||(montage == "C")||(montage=="I")||(montage == "K")
		          taille_1 = "Angle" if (montage=="E")||(montage=="F")||(montage == "G")
		          taille_1 = "Demi" if (montage=="B")||(montage == "D")||(montage=="J")||(montage=="L")||(montage == "H")

		          taille_1 = "Standard" if (montage=="Aa")||(montage == "Ca")||(montage=="Ia")||(montage == "Ka")
		          taille_1 = "Angle" if (montage=="Ea")||(montage=="Fa")||(montage == "Ga")
		          taille_1 = "Demi" if (montage=="Ba")||(montage == "Da")||(montage=="Ja")||(montage=="La")||(montage == "Ha")

		          taille_2 = "Standard" if (montage=="A")||(montage == "D")||(montage=="E")||(montage=="F")
		          taille_2 = "Demi" if (montage=="B")||(montage == "C")||(montage == "H")||(montage == "G")||(montage=="J")||(montage=="K")
		          taille_2 = "Angle" if (montage=="I")||(montage=="L")

		          taille_2 = "Standard" if (montage=="Ab")||(montage == "Db")||(montage=="Eb")||(montage=="Fb")
		          taille_2 = "Demi" if (montage=="Bb")||(montage == "Cb")||(montage == "Hb")||(montage == "Gb")||(montage=="Jb")||(montage=="Kb")
		          taille_2 = "Angle" if (montage=="Ib")||(montage=="Lb")
		          point.x = x12.mm
		        else
		          taille_1 = "Demi" if (montage=="A")||(montage == "C")||(montage == "E")||(montage == "F")||(montage=="I")||(montage == "G")||(montage == "H")||(montage=="K")
		          taille_1 = "Standard" if (montage=="B")||(montage == "D")||(montage=="J")||(montage=="L")

		          taille_1 = "Demi" if (montage=="Aa")||(montage == "Ca")||(montage == "Ea")||(montage == "Fa")||(montage=="Ia")||(montage == "Ga")||(montage == "Ha")||(montage=="Ka")
		          taille_1 = "Standard" if (montage=="Ba")||(montage == "Da")||(montage=="Ja")||(montage=="La")

		          taille_2 = "Demi" if (montage=="A")||(montage == "D")||(montage=="E")||(montage=="F")||(montage=="I")||(montage=="L")
		          taille_2 = "Standard" if (montage=="B")||(montage == "C")||(montage == "G")||(montage == "H")
		          taille_2 = "Angle" if (montage=="J")||(montage=="K")

		          taille_2 = "Demi" if (montage=="Ab")||(montage == "Db")||(montage=="Eb")||(montage=="Fb")||(montage=="Ib")||(montage=="Lb")
		          taille_2 = "Standard" if (montage=="Bb")||(montage == "Cb")||(montage == "Gb")||(montage == "Hb")
		          taille_2 = "Angle" if (montage=="Jb")||(montage=="Kb")
		          point.x = x11.mm
		        end
	        else
		        if !(rang%2!=0)
		          taille_1 = "Standard" if (montage=="A")||(montage == "C")||(montage=="I")||(montage == "K")
		          taille_1 = "Angle" if (montage == "G")
		          taille_1 = "Demi" if (montage=="B")||(montage == "D")||(montage=="E")||(montage=="F")||(montage == "H")||(montage=="J")||(montage=="L")

		          taille_1 = "Standard" if (montage=="Aa")||(montage == "Ca")||(montage=="Ia")||(montage == "Ka")
		          taille_1 = "Angle" if (montage == "Ga")
		          taille_1 = "Demi" if (montage=="Ba")||(montage == "Da")||(montage=="Ea")||(montage=="Fa")||(montage == "Ha")||(montage=="Ja")||(montage=="La")

		          taille_2 = "Standard" if (montage=="A")||(montage == "D")||(montage == "H")
		          taille_2 = "Demi" if (montage=="B")||(montage == "C")||(montage=="E")||(montage=="F")||(montage == "G")||(montage=="J")||(montage=="K")
		          taille_2 = "Angle" if (montage=="I")||(montage=="L")

		          taille_2 = "Standard" if (montage=="Ab")||(montage == "Db")||(montage == "Hb")
		          taille_2 = "Demi" if (montage=="Bb")||(montage == "Cb")||(montage=="Eb")||(montage=="Fb")||(montage == "Gb")||(montage=="Jb")||(montage=="Kb")
		          taille_2 = "Angle" if (montage=="Ib")||(montage=="Lb")
		          point.x = x12.mm
		        else
		          taille_1 = "Demi" if (montage=="A")||(montage == "C")||(montage=="I")||(montage == "G")||(montage=="K")
		          taille_1 = "Standard" if (montage=="B")||(montage == "D")||(montage=="J")||(montage=="L")
		          taille_1 = "Angle" if (montage == "E")||(montage == "F")||(montage == "H")

		          taille_1 = "Demi" if (montage=="Aa")||(montage == "Ca")||(montage=="Ia")||(montage == "Ga")||(montage=="Ka")
		          taille_1 = "Standard" if (montage=="Ba")||(montage == "Da")||(montage=="Ja")||(montage=="La")
		          taille_1 = "Angle" if (montage == "Ea")||(montage == "Fa")||(montage == "Ha")

		          taille_2 = "Demi" if (montage=="A")||(montage == "D")||(montage == "H")||(montage=="I")||(montage=="L")
		          taille_2 = "Standard" if (montage=="B")||(montage == "C")||(montage=="E")||(montage=="F")||(montage == "G")
		          taille_2 = "Angle" if (montage=="J")||(montage=="K")

		          taille_2 = "Demi" if (montage=="Ab")||(montage == "Db")||(montage == "Hb")||(montage=="Ib")||(montage=="Lb")
		          taille_2 = "Standard" if (montage=="Bb")||(montage == "Cb")||(montage=="Eb")||(montage=="Fb")||(montage == "Gb")
		          taille_2 = "Angle" if (montage=="Jb")||(montage=="Kb")
		          point.x = x11.mm
		        end
	      	end
      	end
        long, bloc = mur.ajoute_bloc(point,taille_1,"Gauche",mur.style_angle_gauche) if taille_1
	      bloc.name = mur.dimensions + ";" + mur.largeur.to_s + ";" + taille_1 + ";" +mur.style if(taille_1 == "Standard")||(taille_1 == "Demi")
				bloc.name = mur.dimensions + ";" + mur.largeur.to_s + ";" + taille_1 + "_Gauche" + ";" +mur.style if(taille_1 == "Angle")
        rang_obj.push(bloc) if bloc
        point.x = x2.mm

        if !((montage =~/^\Sa$/)||(montage =~/^\Sc$/))
	        long, bloc = mur.ajoute_bloc(point,taille_2,"Droite",mur.style_angle_droite)
		      bloc.name = mur.dimensions + ";" + mur.largeur.to_s + ";" + taille_2 + ";" +mur.style if(taille_2 == "Standard")||(taille_2 == "Demi")
					bloc.name = mur.dimensions + ";" + mur.largeur.to_s + ";" + taille_2 + "_Droite" + ";" +mur.style if(taille_2 == "Angle")
	        rang_obj.push(bloc) if bloc
	      end
        point.z -= $haut_pmb.mm 
      end
      # linteau de base
	    if !(nb_rangs%2!=0)
	      taille = largeur + 2*$long_pmb if (montage=="A")
	      taille = largeur + $long_pmb if (montage=="B")||(montage == "F")||(montage=="J")
	      taille = largeur + 3*$long_pmb_demi if (montage=="C")||(montage == "D")||(montage == "H")||(montage=="K")
	      taille = largeur + 3*$long_pmb_demi + mur.largeur if (montage=="E")||(montage=="I")
	      taille = largeur + $long_pmb + mur.largeur if (montage=="G")||(montage=="L")
	      if (longueur_linteau % $long_pmb == 0)
	      	taille = longueur_linteau + 2*$long_pmb if (montage=="Aa")||(montage=="Ca")
	      	taille = longueur_linteau + $long_pmb if (montage=="Ba")||(montage=="Da")
	      	taille = longueur_linteau + 3*$long_pmb_demi + mur.largeur if (montage=="Ea")||(montage=="Ga")
	      	taille = longueur_linteau + $long_pmb if (montage=="Fa")||(montage=="Ha")
	      else
	      	taille = longueur_linteau + 3*$long_pmb_demi 
	      	taille = longueur_linteau + $long_pmb + mur.largeur if (montage=="Ea")||(montage=="Ga")
	      	taille = longueur_linteau + $long_pmb if (montage=="Fa")||(montage=="Ha")
	      end
	      point.x = x12.mm
	    else
	      taille = largeur + $long_pmb if (montage=="A")||(montage == "E")||(montage=="I")
	      taille = largeur + 2*$long_pmb if (montage=="B")
	      taille = largeur + 3*$long_pmb_demi if (montage=="C")||(montage == "D")||(montage == "G")||(montage=="L")
	      taille = largeur + 3*$long_pmb_demi + mur.largeur if (montage=="F")||(montage=="J")
	      taille = largeur + $long_pmb + mur.largeur if (montage=="H")||(montage=="K")
	      if (longueur_linteau % $long_pmb == 0)
	      	taille = longueur_linteau + $long_pmb if (montage=="Aa")||(montage=="Ca")
	      	taille = longueur_linteau + 2*$long_pmb if (montage=="Ba")||(montage=="Da")
	      	taille = longueur_linteau + 3*$long_pmb_demi + mur.largeur if (montage=="Fa")||(montage=="Ha")
	      	taille = longueur_linteau + $long_pmb if (montage=="Ea")||(montage=="Ga")
	      else
	      	taille = longueur_linteau + 3*$long_pmb_demi
	      	taille = longueur_linteau + $long_pmb + mur.largeur if (montage=="Fa")||(montage=="Ha")
	      end
	      taille = 0 if ((montage =~/^\Sb$/)||(montage =~/^\Sc$/))
	      point.x = x11.mm
	    end
      long, bloc = mur.ajoute_bloc(point,"Standard",nil,nil,"Sur mesure", taille) 
      bloc.name = long.to_i.to_s + ";" + mur.largeur.to_s + ";" + "Lisse basse fenetre" + ";" + mur.style if point.z==z_min.mm if bloc
      rang_obj.push(bloc) if bloc
			# recherche des groupes
			# -----------------------------
			liste_groupe = "" 
			liste_composant = ""
			liste_groupes = Array.new()
			liste_composants = Array.new()
			rang_obj.each do |groupe|
				if groupe.typename == "Group"
					liste_groupe += (mur.nom + ";" + groupe.name+ "-")
				end
				if groupe.typename == "ComponentInstance"
					liste_composant += (mur.nom + ";" + groupe.name+ "-")
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
      rang = modele.add_group(rang_obj)
			#return point, nil if !bloc
		  rang.set_attribute("Info élément", "nom", self.nom)
		  rang.set_attribute("Info élément", "type", table[:type])
      rang.set_attribute("Info élément", "liste_composant", table[:liste_composant])
      rang.name = "fenetre"
      sauve_options_dessin(rang)
      return point, rang     
    end
    
  end #class Fenetre

end # module PMB
