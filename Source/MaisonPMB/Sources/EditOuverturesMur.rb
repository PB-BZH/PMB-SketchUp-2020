module PMB
  #------------------------- Outils d'edition des murs ------------------------------------
  
  # Edition des fenêtres. Initialiser cet outil par un clic gauche sur un mur. Ensuite,
  # un clic doit affiche le menu contextuel:
  # - Modifie les propriétés de la fenêtre
  # - Déplace fenêtre
  # - Efface une fenetre     
  #--------------------------------------------------- ------------------------------------
  class Edit_Ouvertures_Mur < Outils_Fenetre
    attr_accessor :obj, :mur, :operation 
    
    def initialize(grp_mur, type_objet, operation)
      @operation = operation
      @type_objet = type_objet
      @mur = creation_mur_pour_dessin(grp_mur)
      @decalage = 0
      @selection_obj = nil
      @pt_a_deplacer = nil
      @pt_depart = nil
      @coins = []
      reset()
      return true
    end
    
    def reset()
      @etat = STATE_SELECT
      Sketchup::set_status_text "[#{@operation} #{@type_objet}] Survoler la zone #{@type_objet} et cliquer lorsqu'elle est mise en évidence"
      Sketchup::set_status_text "", SB_VCB_VALUE
      Sketchup::set_status_text "", SB_VCB_VALUE
      @drawn = false
    end
    
    def activate
    	Sketchup.active_model.options["UnitsOptions"]["LengthSnapEnabled"]=true
    	Sketchup.active_model.options["UnitsOptions"]["LengthSnapLength"]=30.cm.to_l
      @ip1 = Sketchup::InputPoint.new
      @ip = Sketchup::InputPoint.new
      @mur.masquer_groupe
    end
    
    def deactivate(view)
      Sketchup.active_model.options["UnitsOptions"]["LengthSnapEnabled"]=true
      Sketchup.active_model.options["UnitsOptions"]["LengthSnapLength"]=1.cm.to_l
      affiche_calque(@mur.calque + "_epure",false)
      view.invalidate if @drawn
      @ip1 = nil
      @mur.afficher_groupe
    end
    
    def onCancel(flag, view)
    	affiche_calque(@mur.calque + "_epure",false)
      puts "Quitte #{@operation} Fenêtre" if $VERBOSE
      Sketchup.active_model.select_tool(nil)
    end
    
    def rechercher_selection_objets(x, y, view)
      return nil if(@coins.length != 5)
      pickray = view.pickray(x, y)
      base_mur = [@coins[0], $axe_Z]
      debut = Geom::intersect_line_plane(pickray, base_mur)
      return nil if not debut
      
      point = Geom::Point3d.new(debut)
      rotation = Geom::Transformation.rotation(@coins[0], $axe_Z, -@mur.angle.degrees)
      debut_mur = Geom::Point3d.new(@mur.pt_debut)
      fin_mur = Geom::Point3d.new(@mur.pt_fin)
      if (@mur.angle != 0)
        debut_mur.transform!(rotation)
        fin_mur.transform!(rotation)
        point.transform!(rotation)
      end
      vec_mur = fin_mur - debut_mur
      @mur.objets.each do |obj|
        vec_mur.length = obj.center_offset.mm - obj.largeur.mm/2
        debut_obj = debut_mur + vec_mur 
        vec_mur.length = obj.largeur.mm
        fin_obj = debut_obj + vec_mur
        vec_obj = fin_obj - debut_obj
        next if(vec_obj.length <= 0)

        case (@mur.justification)
        when "Gauche"
          transform = Geom::Transformation.new(debut_obj, [0,0,1], 90.degrees)
        when "Droite"
          transform = Geom::Transformation.new(debut_obj, $axe_Z,  -90.degrees)
        when "Centre"
          # Rien
        else
          transform = Geom::Transformation.new()
          UI.messagebox("justification non valide")
        end
        vec_obj.transform!(transform)
        vec_obj.length = @mur.largeur.mm
        debut_offset_obj = debut_obj.offset(vec_obj)
        if((point.y > min(debut_obj.y, fin_obj.y)) &&
           (point.y < max(debut_obj.y, fin_obj.y)) &&
           (point.x > min(debut_obj.x, debut_offset_obj.x)) &&
           (point.x < max(debut_obj.x, debut_offset_obj.x)))
           #UI.messagebox("Point trouvé !!!")
           view.invalidate
           return obj
        end
      end
      return nil
    end
    
    def onMouseMove(flags, x, y, view)
      @ip.pick(view, x, y)
      view.tooltip = @ip.tooltip if @ip.valid?
      @mouvement = true
      @ip.pick(view, x, y, @pt_depart)
      view.tooltip = @ip.tooltip if @ip.valid?
      return if not @ip.valid?
      if (@etat == STATE_MOVING && @selection_obj)
          vec = @mur.pt_fin - @mur.pt_debut
          point = @ip.position.project_to_line(@mur.pt_debut, @mur.pt_fin)
          debut_vec = point - @mur.pt_debut
          if ((debut_vec.length == 0) || (debut_vec.samedirection?(vec)))
              @decalage = @mur.pt_debut.distance point
          else
              @decalage = 0    # point is beyond wall origin
          end
          Sketchup::set_status_text(@decalage.to_s, SB_VCB_VALUE)
          trouve_point_final()
      elsif (@etat == STATE_SELECT)
          @selection_obj = rechercher_selection_objets(x, y, view) 
      end
      view.invalidate
    end
      

    def getExtents
      bb = Geom::BoundingBox.new
        bb.add(@mur.pt_debut)
        bb.add(@mur.pt_fin)
      return bb
    end
    
    def draw(view)
      # Show the current input point
      if (@ip.valid? && @ip.display?)
          @ip.draw(view)
          @drawn = true
      end 
      @coins[0] = @mur.pt_debut
      @coins[1] = @mur.pt_fin
      (a, b) = dessine_contour(view, @coins[0], @coins[1], @mur.largeur, @mur.justification, "green", 1)
      @coins[2] = b
      @coins[3] = a
      @coins[4] = @coins[0]
      vec = @coins[1] - @coins[0]
      @mur.objets.each do |obj|
        vec.length = obj.center_offset.mm - obj.largeur.mm/2.0
        debut_obj = @mur.pt_debut + vec
        vec.length = obj.largeur.mm
        fin_obj = debut_obj + vec
        if (defined?(@selection_obj) && (obj == @selection_obj))
          if (@etat != STATE_MOVING)
            dessine_contour(view, debut_obj, fin_obj, @mur.largeur, @mur.justification, "red", 4)
          end
        else
          dessine_contour(view, debut_obj, fin_obj, @mur.largeur, @mur.justification, "blue", 2)
        end
      end
      if (@etat == STATE_MOVING)
        dessine_contour(view, @debut, @fin, @mur.largeur, @mur.justification, "yellow", 2)
      end
      @drawn = true
    end
    
    def dessine_objet()
			@selection_obj.montage = nil if (@operation == "DEPLACE")||(@operation == "MODIFIE")
    	if !(@selection_obj.montage) && !(@operation == "EFFACE")
    		@obj = @selection_obj
    		choix_montage_fenetre()
		  end
		  @mur.dimensions = "Sur mesure"
      modele = Sketchup.active_model
      modele.start_operation("Redessinne la #{@type_objet}")      
		  	@mur.effacer_groupe()
	      @mur.draw()
      modele.commit_operation
    end
    
    def onLButtonDown(flags, x, y, view)
      if ((@etat == STATE_MOVING) && @mouvement)
        vec = @fin - @debut
        vec.length = vec.length/2
        center = @debut + vec
        @selection_obj.center_offset = (@mur.pt_debut.distance center).to_mm.round.to_i
        @selection_obj.x_debut = (@mur.pt_debut.distance @debut).to_mm.round.to_i
        @selection_obj.x_fin = (@mur.pt_debut.distance @fin).to_mm.round.to_i
        dessine_objet()  
        Sketchup.active_model.select_tool(nil) 
      elsif (@etat == STATE_SELECT)
        faire_operation if @selection_obj
      end
    end

    def faire_operation
        case @operation
        when "MODIFIE"
          affiche_dialogue
        when "DEPLACE"
          deplace
        when "EFFACE"
          efface_objet
        end
    end
    
    def affiche_dialogue
      case @type_objet
      when "Fenetre"
        results = @selection_obj.options_Fenetres()
      when "Porte"
        results = @selection_obj.options_Portes()
      else
        results = "Erreur"
      end
      if(results)
        dessine_objet()
      end
      Sketchup.active_model.select_tool(nil)
    end
    
    def deplace
        return if not @selection_obj
        @etat = STATE_MOVING
        @obj = @selection_obj
      	if (@selection_obj.montage =~/^\S\S$/)
      		case @selection_obj.montage
      		when /^\Sa$/
      			index_inf, index_sup = recherche_obj_adjacent(@selection_obj)
      			case (@mur.objets[index_sup].montage)
      				when /^\Sc$/ 
      					puts @mur.objets[index_sup].montage
      					@mur.objets[index_sup].montage = @mur.objets[index_sup].montage[0,1]
      					@mur.objets[index_sup].montage += "a"
      				when /^\Sb$/
      					puts @mur.objets[index_sup].montage
      					@mur.objets[index_sup].montage = @mur.objets[index_sup].montage[0,1]
      					puts @mur.objets[index_sup].montage
      				end
      		when /^\Sb$/
      			index_inf, index_sup = recherche_obj_adjacent(@selection_obj)
      			case (@mur.objets[index_inf].montage)
      				when /^\Sc$/ 
      					@mur.objets[index_inf].montage = @mur.objets[index_inf].montage[0,1]
      					@mur.objets[index_inf].montage += "b"
      				when /^\Sa$/
      					puts @mur.objets[index_inf].montage
      					@mur.objets[index_inf].montage = @mur.objets[index_inf].montage[0,1]
      				end
      		when /^\Sc$/
      			index_inf, index_sup = recherche_obj_adjacent(@selection_obj)
      			@mur.objets[index_sup].montage = @mur.objets[index_sup].montage[0,1]
      			@mur.objets[index_inf].montage = @mur.objets[index_inf].montage[0,1]
      		end
      		@selection_obj.montage = nil
      	end
      	@selection_obj.montage = nil
        @decalage = @obj.center_offset
        trouve_point_final()
        vec = @fin - @debut
        vec.length = vec.length/2
        @pt_a_deplacer = @debut + vec
        @pt_depart = Sketchup::InputPoint.new(@pt_a_deplacer)
    end
    
    def efface_objet
      result = UI.messagebox("Effacer cette #{@type_objet} ?" , MB_YESNO, "Supprimer")
      if (result == 6)
      	if (@selection_obj.montage =~/^\S\S$/)
      		case @selection_obj.montage
      		when /^\Sa$/
      			index_inf, index_sup = recherche_obj_adjacent(@selection_obj)
      			case (@mur.objets[index_sup].montage)
      				when /^\Sc$/ 
      					@mur.objets[index_sup].montage = @mur.objets[index_sup].montage[0,1]
      					@mur.objets[index_sup].montage += "a"
      				when /^\Sb$/
      					@mur.objets[index_sup].montage = @mur.objets[index_sup].montage[0,1]
      				end
      		when /^\Sb$/
      			index_inf, index_sup = recherche_obj_adjacent(@selection_obj)
      			case (@mur.objets[index_inf].montage)
      				when /^\Sc$/ 
      					@mur.objets[index_inf].montage = @mur.objets[index_inf].montage[0,1]
      					@mur.objets[index_inf].montage += "b"
      				when /^\Sa$/
      					@mur.objets[index_inf].montage = @mur.objets[index_inf].montage[0,1]
      				end
      		when /^\Sc$/
      			index_inf, index_sup = recherche_obj_adjacent(@selection_obj)
      			@mur.objets[index_sup].montage = @mur.objets[index_sup].montage[0,1]
      			@mur.objets[index_inf].montage = @mur.objets[index_inf].montage[0,1]
      		end
      		@selection_obj.montage = nil
      	end
      	@objets = @selection_obj
        @mur.effacer_objet(@selection_obj.nom)
        @mur.effacer_objet_classes(@selection_obj.nom)
        dessine_objet()
      end
      Sketchup.active_model.select_tool(nil)
    end
  end
end