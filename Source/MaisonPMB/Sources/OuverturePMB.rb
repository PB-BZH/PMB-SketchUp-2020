module PMB
  #----------------------------- O P E N I N G -----------------------
  # Classe de base pour les portes et les fenêtres
  #-------------------------------------------------------------------
  class Ouverture < Base_PMB
    
    attr_accessor :config_objets, :objets, :objets_classes, :montage_mur

    def initialize(options = {})
      defaut = {
        'nom'       => '',
        'x_debut'   => 0,
        'x_fin'     => 0,
        'z_max'     => 0,
        'z_min'     => 0,
        'nb_rangs'  => 0,
        'montage'   => '',
      }
      applique_options_globales(defaut)
      defaut.update(options)
      super(defaut)
      @objets = []
      @montage_mur = ""
      if (self.nom.length == 0)
        self.nom = PMB::Base_PMB.nom_unique("Ouverture")
      end
    end
    
    def ajouter_objet(objet, options = {})
      @objets_classes.push(objet)
    end
    
    def effacer_objet(nom)
      @objets_classes.delete_if {|x| x.nom == nom }
    end
  end
  
  class Ouverture_PMB < Base_PMB
    def classer_objets(mur = self)
      data = []
      data_haut = []
      objets = mur.objets
      table = []
      index = nil
      x_debut = nil
      x_min = nil
      bas = true
      nb = objets.length
      for i in 0...nb
        x_min = mur.longueur.mm
        z_mur = mur.hauteur
        objets.each do |obj|
          x_debut = obj.x_debut.mm
          if obj.z_min < z_mur
	          if x_debut < x_min
	          	bas = true
	            index = objets.index(obj)
	            x_min = x_debut
	            obj_nom      = objets[index].nom
	            obj_x_debut  = objets[index].x_debut
	            obj_x_fin    = objets[index].x_fin
	            obj_z_max    = objets[index].z_max
	            obj_z_min    = objets[index].z_min
	            obj_nb_rangs = objets[index].nb_rangs
	            obj_montage  = objets[index].montage
	            @ouverture = Ouverture.new(remplir_options(
	                %w[style layer],
	                'nom'     => obj_nom,
	                'x_debut' => obj_x_debut,
	                'x_fin'   => obj_x_fin,
	                'z_max'   => obj_z_max,
	                'z_min'   => obj_z_min,
	                'nb_rangs'=> obj_nb_rangs,
	                'montage' => obj_montage
	            ))
	          else
	            next
	          end
	        else
	          if x_debut < x_min
	            index = objets.index(obj)
	            bas = false
	            x_min = x_debut
	            obj_nom      = objets[index].nom
	            obj_x_debut  = objets[index].x_debut
	            obj_x_fin    = objets[index].x_fin
	            obj_z_max    = objets[index].z_max
	            obj_z_min    = objets[index].z_min
	            obj_nb_rangs = objets[index].nb_rangs
	            obj_montage  = objets[index].montage
	            @ouverture_haut = Ouverture.new(remplir_options(
	                %w[style layer],
	                'nom'     => obj_nom,
	                'x_debut' => obj_x_debut,
	                'x_fin'   => obj_x_fin,
	                'z_max'   => obj_z_max,
	                'z_min'   => obj_z_min,
	                'nb_rangs'=> obj_nb_rangs,
	                'montage' => obj_montage
	            ))
	          else
	            next
	          end
          end
        end
        table.push(mur.objets[index])
        mur.objets.delete_at(index)
        data.push(@ouverture) if bas
        data_haut.push(@ouverture_haut) 
        mur.ajouter_objet_classes(@ouverture) if bas
        mur.objets_classes_pignon.push(@ouverture_haut) if !bas
      end
      mur.objets = table
      data = corriger_montage_ouverture(data, mur)
      return 
    end
    
    def corriger_montage_ouverture(table, mur)
    	taille = table.length - 1
    	parite = []
    	montage = []
    	index = nil
    	for i in 1..taille do
    		if ((table[i].x_debut - table[i-1].x_fin) <= 900)
    			mur.objets.each {|obj| index = mur.objets.index(obj) if (obj.x_debut == table[i].x_debut)}
    			#puts index
    			parite[0] = (table[i-1].nb_rangs % 2) == 0
    			parite[1] = (table[i].nb_rangs % 2) == 0
    			montage[0] = table[i-1].montage
    			montage[1] = table[i].montage
    			#puts("parite precedente = #{ parite[0]}, parite suivante = #{ parite[1]}")
    			#puts("montage precedent = #{montage[0]}, montage suivant = #{montage[1]}")
    			#puts("montage fenetre = #{mur.objets[index].montage}")
    			if (parite[0] == parite[1])
    				if (montage[0] == montage[1])
    					if (montage[1] == "A")
    						mur.objets[index].montage = table[i].montage = "B"
    					elsif (montage[1] == "B")
    						mur.objets[index].montage = table[i].montage = "A"
    					end 
    				end
    			elsif (montage[0] != montage[1])
  					if (montage[1] == "A")
  						mur.objets[index].montage = table[i].montage = "B"
  					elsif (montage[1] == "B")
  						mur.objets[index].montage = table[i].montage = "A"
  					end 
    			end
    			#puts("montage precedent = #{montage[0]}, montage suivant = #{montage[1]}")
    			#puts("montage fenetre = #{mur.objets[index].montage}\n")
    		end
    	end if taille > 0
    	return table
    end
  end # class Opening
end # module PMB