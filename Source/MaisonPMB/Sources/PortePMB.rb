module PMB
  #----------------------------- P O R T E S ---------------------------
  # A Door has studs, headers, and cripples.
  
  #----------------------------- P O R T E S ---------------------------
  class Porte < Ouverture_PMB
  
    def initialize(options = {})
      defaut_options_porte = { 
        'element'         => 'Porte',
        'nom'             => '',
        'x_debut'         => 0,
        'x_fin'           => 0,
        'justification'   => 'Gauche',
        'hauteur_linteau' => 2210,
        'longueur_linteau'=> 0,
        'center_offset'   => 0,
        'largeur'         => 900,
        'hauteur'         => 2125,
        'nb_rangs'        => 0,
        'z_max'           => 0,
        'z_min'           => 0,
        'montage'         => nil,
        'index'           => nil,
        'calque'          => 'Porte',
        'rough_opening' => 1.cm,
      }
      applique_options_globales(defaut_options_porte)
      defaut_options_porte.update(options)
      super(defaut_options_porte)
      if (self.nom.length == 0)
        self.nom = Base_PMB.nom_unique("porte")
      end
    end
  
    def calcul_nb_rang
      bloc_pmb = Bloc_PMB.new
      nombre = (self.hauteur/bloc_pmb.hauteur).round
      hauteur_pmb = nombre * bloc_pmb.hauteur
      z_max = self.hauteur_linteau
      z_min = (z_max - hauteur_pmb)
      #puts z_min.to_s + ", " + z_max.to_s + ", "
      return nombre, z_max, z_min
    end
    
    def options_Portes(obj = self)
      proprietes_porte = [
        # prompt, attr_name, value, enums
        [ "Justification des portes", "porte.justification", "Gauche|Centre|Droite" ],
        [ "Hauteur du linteau", "porte.hauteur_linteau", nil ],
        [ "largeur de la porte", "porte.largeur", nil ],
        [ "Hauteur de la porte", "porte.hauteur", nil ],
        [ "Montage de la porte", "porte.montage", "A|Aa|Ab|Ac|B|Ba|Bb|Bc|C|Ca|Cb|Cc|D|Da|Db|Dc|E|Ea|Eb|Ec|F|Fa|Fb|Fc|G|Ga|Gb|Gc|H|Ha|Hb|Hc|I|Ia|Ib|Ic|J|Ja|Jb|Jc|K|Ka|Kb|Kc|L|La|Lb|Lc"],
      ].freeze
      results = affiche_dialogue("Propriétés des portes", obj, proprietes_porte)
      obj.x_debut = obj.center_offset - obj.largeur/2.0
      obj.x_fin = obj.center_offset + obj.largeur/2.0
      obj.nb_rangs, obj.z_max, obj.z_min  = calcul_nb_rang()
      return false if not results
      return results
    end
  
   def self.creation_pour_dessin(group)
        porte = Porte.new()
        porte.recupere_option_dessin(group)
        return porte
    end
    
    def dessine_objet(mur, coord, obj = self)
      #UI.messagebox("objet = #{obj.inspect}")
      modele = Sketchup.active_model.entities
      point=Geom::Point3d.new
      point=point.set!(coord)
      rang_obj = []
      x1= x_debut
      puts("montage de la porte #{obj.montage}") if $DEBUG
      parite_z_max = (z_max / $haut_pmb) % 2 == 0
      case (parite_z_max)
      when false
	      if(montage == "A")||(montage == "C")||(montage == "E")||(montage == "G")||(montage == "I")||(montage == "K")||
	      	(montage == "Aa")||(montage == "Ca")||(montage == "Ea")||(montage == "Ga")||(montage == "Ia")||(montage == "Ka")
	        x11 = x1 - $long_pmb
	        x11 = x1 - $long_pmb_demi - mur.largeur if (montage == "E") || (montage == "G")||(montage == "Ea") || (montage == "Ga")
	        x12 = x1 - $long_pmb_demi
	      else
	        x11 = x1 - $long_pmb_demi
	        x12 = x1 - $long_pmb
	        x12 = x1 - $long_pmb_demi - mur.largeur if (montage == "F") || (montage == "H")||(montage == "Fa") || (montage == "Ha")
	      end
	    when true
	      if(montage == "A")||(montage == "C")||(montage == "E")||(montage == "G")||(montage == "I")||(montage == "K")||
	      	(montage == "Aa")||(montage == "Ca")||(montage == "Ea")||(montage == "Ga")||(montage == "Ia")||(montage == "Ka")
	        x11 = x1 - $long_pmb_demi
	        x12 = x1 - $long_pmb
	        x12 = x1 - $long_pmb_demi - mur.largeur if (montage == "E") || (montage == "G")||(montage == "Ea") || (montage == "Ga")
	      else
	        x11 = x1 - $long_pmb
	        x11 = x1 - $long_pmb_demi - mur.largeur if (montage == "F") || (montage == "H")||(montage == "Fa") || (montage == "Ha")	                                                   
	        x12 = x1 - $long_pmb_demi
	      end
      end
      x11 = x12 = x1 if (montage =~/^\Sb$/)||(montage =~/^\Sc$/)
      x2 = x_fin
      point.z = z_max.mm
      # linteau de tête
      if (longueur_linteau % $long_pmb == 0)
      	taille = longueur_linteau + 2*$long_pmb if (montage=="Aa")||(montage=="Ca")
      	taille = longueur_linteau + $long_pmb if (montage=="Ba")||(montage=="Da")
      	taille = longueur_linteau + 3*$long_pmb_demi + mur.largeur if (montage=="Ea")||(montage=="Ga")
      	taille = longueur_linteau + $long_pmb if (montage=="Fa")||(montage=="Ha")
      else
      	taille = longueur_linteau + 3*$long_pmb_demi if (montage =~/^\S$/)||(montage =~/^\Sa$/)
      	taille = longueur_linteau + $long_pmb + mur.largeur if (montage=="Ea")||(montage=="Ga")
      end
      taille = 0 if (montage =~/^\Sb$/)||(montage =~/^\Sc$/)
      taille = largeur + 2*$long_pmb if (montage=="A") 
      taille = largeur + $long_pmb if (montage=="B")||(montage=="F")||(montage=="J")
      taille = largeur + $long_pmb + mur.largeur if (montage=="G")||(montage=="L")
      taille = largeur + 3*$long_pmb_demi if (montage=="C")||(montage=="D")||(montage=="H")||(montage=="K")
      taille = largeur + 3*$long_pmb_demi + mur.largeur if (montage=="E")||(montage=="I")
      point.x = x12.mm
      long, bloc = mur.ajoute_bloc(point,"Standard",nil,nil,"Sur mesure", taille) if (taille !=0) if !((montage =~/^\Sb$/)||(montage =~/^\Sc$/))
      rang_obj.push(bloc) if( taille !=0) if !((montage =~/^\Sb$/)||(montage =~/^\Sc$/))
      point.z -= $haut_pmb.mm
      
      # MONTAGE DE L'OUVERTURE
      for rang in 0..(nb_rangs-1)
        if (rang%2!=0) 
          taille_1 = "Standard" if (montage=="A")||(montage == "C")||(montage=="I")||(montage=="K")
          taille_1 = "Angle" if (montage=="E")||(montage == "G")
          taille_1 = "Demi" if (montage=="B")||(montage == "D")||(montage=="F")||(montage == "H")||(montage=="J")||(montage=="L")
          taille_1 = "Standard" if (montage=="Aa")||(montage == "Ca")||(montage=="Ia")||(montage=="Ka")
          taille_1 = "Angle" if (montage=="Ea")||(montage == "Ga")
          taille_1 = "Demi" if (montage=="Ba")||(montage == "Da")||(montage=="Fa")||(montage == "Ha")||(montage=="Ja")||(montage=="La")

          taille_2 = "Standard" if (montage=="A")||(montage == "D")||(montage=="E")||(montage == "H")
          taille_2 = "Demi" if (montage=="B")||(montage == "C")||(montage=="F")||(montage == "G")||(montage=="J")||(montage=="K")
          taille_2 = "Angle" if (montage=="I")||(montage=="L")
          taille_2 = "Standard" if (montage=="Ab")||(montage == "Db")||(montage=="Eb")||(montage == "Hb")
          taille_2 = "Demi" if (montage=="Bb")||(montage == "Cb")||(montage=="Fb")||(montage == "Gb")||(montage=="Jb")||(montage=="Kb")
          taille_2 = "Angle" if (montage=="Ib")||(montage=="Lb")
          point.x = x12.mm
        else
          taille_1 = "Demi" if (montage=="A")||(montage == "C")||(montage == "E")||(montage == "G")||(montage=="I")||(montage=="K")
          taille_1 = "Standard" if (montage=="B")||(montage == "D")||(montage=="J")||(montage=="L")
          taille_1 = "Angle" if (montage == "F")||(montage == "H")
          taille_1 = "Demi" if (montage=="Aa")||(montage == "Ca")||(montage == "Ea")||(montage == "Ga")||(montage=="Ia")||(montage=="Ka")
          taille_1 = "Standard" if (montage=="Ba")||(montage == "Da")||(montage=="Ja")||(montage=="La")
          taille_1 = "Angle" if (montage == "Fa")||(montage == "Ha")

          taille_2 = "Demi" if (montage=="A")||(montage == "D")||(montage=="E")||(montage == "H")||(montage=="I")||(montage=="L")
          taille_2 = "Standard" if (montage=="B")||(montage == "C")||(montage=="F")||(montage == "G")
          taille_2 = "Angle" if (montage=="J")||(montage=="K")
          taille_2 = "Demi" if (montage=="Ab")||(montage == "Db")||(montage=="Eb")||(montage == "Hb")||(montage=="Ib")||(montage=="Lb")
          taille_2 = "Standard" if (montage=="Bb")||(montage == "Cb")||(montage=="Fb")||(montage == "Gb")
          taille_2 = "Angle" if (montage=="Jb")||(montage=="Kb")
          point.x = x11.mm
        end
        long, bloc = mur.ajoute_bloc(point,taille_1,"Gauche",mur.style_angle_gauche) if taille_1
        rang_obj.push(bloc) if bloc
        point.x = x2.mm
        long, bloc = mur.ajoute_bloc(point,taille_2,"Droite",mur.style_angle_droite) if taille_2
        rang_obj.push(bloc) if bloc
        point.z -= $haut_pmb.mm 
      end
      rang = modele.add_group(rang_obj)
      sauve_options_dessin(rang)
      return point, rang      
    end
  end
end