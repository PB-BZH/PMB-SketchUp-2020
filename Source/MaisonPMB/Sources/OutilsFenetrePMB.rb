module PMB
#------------------------------------------------------------------------------------------
  class Outils_Fenetre
  # --------------- Outil MURS ----------------------------------------
  # Cette classe est utilisée pour dessiner un mur. Elle doit afficher
  # une boîte de dialogue  et permettre de dessiner un ou plusieurs 
  # murs utilisant ces propriétés. 
  # Appuyer sur Echap pour sortir de l'outils
  # -------------------------------------------------------------------
    
    def initialize(groupe_mur)
      @obj = Fenetre.new()
      @obj.options_Fenetres()
      #puts(@obj.inspect)
      @mur = creation_mur_pour_dessin(groupe_mur)
      @objtype = "Fenêtre"
      @fin = @debut = Geom::Point3d.new
      reset
      return true
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
        affiche_calque(@mur.calque + "_epure", false)
        view.invalidate if @drawn
        @ip1 = nil
        @mur.afficher_groupe
    end
    
    def reset
        @pts = []
        @state = STATE_MOVING
        Sketchup::set_status_text "[ADD #{@objtype}] Utiliser la souris pour deplacer #{@objtype}; cliquer pour le positionner #{@objtype}"
        Sketchup::set_status_text "#{@obj.justification} décalage", SB_VCB_LABEL
        Sketchup::set_status_text "", SB_VCB_VALUE
        @drawn = false
    end
    
    def onCancel(flag, view)
      puts "Quitte ajout Porte ou Fenêtre" if $VERBOSE
        view.invalidate if @drawn
        Sketchup.active_model.select_tool(nil)
        reset
    end
    
    def onLButtonDown(flags, x, y, view)
        self.set_current_point(x, y, view)
        self.draw_obj
        Sketchup.active_model.select_tool(nil)
    end
    
    def onRButtonDown(flags, x, y, view)
      @obj.options_Fenetres()
    end

    def onKeyDown(key, repeat, flags,view)
      @obj.options_Fenetres() if (key==123)     # Touche F12
    end

    def onMouseMove(flags, x, y, view)
      self.set_current_point(x, y, view)
    end
    
    # allow the user to type in the distance to the window from the 
    # start of the wall
    def onUserText(text, view)
      # The user may type in something that we can't parse as a length
      # so we set up some exception handling to trap that
      begin
          value = text.to_i.mm
      rescue
          # Error parsing the text
          UI.beep
          value = nil
          Sketchup::set_status_text "", SB_VCB_VALUE
      end
      return if !value
      
      # update the offset of the window or door
      @decalage = value
      find_end_points
      view.invalidate
      self.draw_obj
      Sketchup.active_model.select_tool(nil)
    end
    
    # find the points on the left and right side of the window
    def trouve_point_final
    	$MUR_MIN = @mur.largeur + $long_pmb_demi
      vec = @mur.pt_fin - @mur.pt_debut
      case @obj.justification
      when "Gauche"
          # do nothing
      when "Centre"
          @decalage -= @obj.largeur.mm/2.0
      when "Droite"
          @decalage -= @obj.largeur.mm
      else
          UI.messagebox "invalid justification"
      end
      
      # make sure we have not extended beyond the end of the wall
      if ((@decalage + @obj.largeur.mm) > (@mur.longueur.mm - $MUR_MIN.mm))
          @decalage = @mur.longueur.mm - @obj.largeur.mm - $MUR_MIN.mm
      end
      
      # make sure we have not extended beyond the beginning of the wall
      if (@decalage <= $MUR_MIN.mm)
          vec.length = $MUR_MIN.mm
          @debut = @mur.pt_debut + vec
      else
          vec.length = @decalage
          @debut = @mur.pt_debut + vec
      end
      vec.length = @obj.largeur.mm
      @fin = @debut + vec
    end
    
    # recompute the start and end points as the window is tracking the mouse
    def set_current_point(x, y, view)
        if (!@ip.pick(view, x, y, @ip1))
            return false
        end
        need_draw = true
        
        # Set the tooltip that will be displayed
        view.tooltip = @ip.tooltip
            
        # Compute points
        if (@state == STATE_MOVING)
            vec = @mur.pt_fin - @mur.pt_debut
            point = @ip.position.project_to_line(@mur.pt_debut, @mur.pt_fin)
            start_vec = point - @mur.pt_debut
            if ((start_vec.length == 0) || (start_vec.samedirection?(vec)))
                @decalage = (@mur.pt_debut.distance point)
            else
                @decalage = 0    # point is beyond wall pt_debut
            end
            Sketchup::set_status_text(@decalage.to_s, SB_VCB_VALUE)
            
            trouve_point_final
        end
        view.invalidate if need_draw
    end
    
    def choix_montage_fenetre()
    	largeur_fenetre = @obj.largeur
    	nb_rangs = @obj.nb_rangs
    	z_max = @obj.z_max
    	x_debut = @obj.x_debut
    	x_fin = @obj.x_debut + @obj.largeur
    	type_mur = @mur.montage
    	largeur_mur = @mur.largeur
			parite_z_max = (z_max / $haut_pmb)%2 == 0
    	if(type_mur =~/^\S1$/)
    		if parite_z_max
    			resultat = (x_debut - largeur_mur) % $long_pmb
    		else
    			resultat = (x_debut - largeur_mur - $long_pmb_demi) % $long_pmb
    		end
    	else
    		if ((z_max / $haut_pmb)%2 == 0)
    			resultat = (x_debut - largeur_mur - $long_pmb_demi) % $long_pmb
    		else
    			resultat = (x_debut - largeur_mur) % $long_pmb
    		end
    	end
  		$fenetre_bord_gauche = true if (x_debut == ($long_pmb_demi + @mur.largeur))
  		$fenetre_bord_droit = true if (x_fin == (@mur.longueur - $long_pmb_demi - @mur.largeur))
    	ecart = resultat
    	if (ecart == $long_pmb_demi)
    		cas = "CAS_1"
    	else
    		cas = "CAS_2"
    	end
    	n = ((largeur_fenetre/$long_pmb_demi)-1)/2.0
    	if (n == n.to_int)
      	case (parite_z_max)
	      	when true
	      		if (cas == "CAS_1")
	      			montage = "C"
	      			montage = "G" if $fenetre_bord_gauche
	      			montage = "K" if $fenetre_bord_droit
	      		else
	      			montage = "D"
	      			montage = "H" if $fenetre_bord_gauche
	      			montage = "L" if $fenetre_bord_droit
	      		end
	      	when false
	          if (cas == "CAS_1")
	            montage = "C"
	            montage = "G" if $fenetre_bord_gauche
	            montage = "K" if $fenetre_bord_droit
	          else
	            montage = "D"
	            montage = "H" if $fenetre_bord_gauche
	            montage = "L" if $fenetre_bord_droit
	          end
        end
    	else
    		case (parite_z_max)
    			when true
		    		if (cas == "CAS_1")
		    			montage = "A"
		    			montage = "E" if $fenetre_bord_gauche
		    			montage = "I" if $fenetre_bord_droit
		    		else
		    			montage = "B"
		    			montage = "F" if $fenetre_bord_gauche
		    			montage = "J" if $fenetre_bord_droit
		    		end
				  when false
		    		if (cas == "CAS_1")
		    			montage = "A"
		    			montage = "E" if $fenetre_bord_gauche
		    			montage = "I" if $fenetre_bord_droit
		    		else
		    			montage = "B"
		    			montage = "F" if $fenetre_bord_gauche
		    			montage = "J" if $fenetre_bord_droit
		    		end
		    	end
  		end
  		$fenetre_bord_gauche = false if $fenetre_bord_gauche
			$fenetre_bord_droit = false if $fenetre_bord_droit
			index_inf, index_sup = recherche_obj_adjacent()
			if (index_inf || index_sup)
				obj1 = @mur.objets[index_inf] if index_inf
				obj2 = @mur.objets[index_sup] if index_sup
   			if (obj1.montage =~/^\S$/)
   				obj1.montage += "a"
   				obj1.index = index_inf
   			end if obj1
   			if (obj1.montage =~/^\Sb$/)
   				obj1.montage[1,1] = "c"
   				montage += "b"
   				obj1.index = index_inf
   			else
   				montage += "b"
   				obj1.index = index_inf
   			end if obj1
   			if (obj2.montage =~/^\S$/)
   				obj2.montage += "b"
   				obj2.index = index_sup
   			end if obj2
   			if (obj2.montage =~/^\Sa$/)
   				obj2.montage[1,1] = "c"
   				montage += "a"
   				obj2.index = index_sup
   			else
   				montage += "a"
   				obj2.index = index_sup
   			end if obj2
   			
   			@mur.objets.each {|ent| $index_A = ent.index if (ent.montage =~/^\Sa$/)}
   			@mur.objets.each {|ent| $index_B = ent.index if (ent.montage =~/^\Sb$/)}
   			if ($index_B)
   				@mur.objets[$index_B].longueur_linteau = (@mur.objets[$index_B].x_fin - @obj.x_debut).abs
   				@obj.longueur_linteau = @mur.objets[$index_B].longueur_linteau
  				puts(@mur.objets[$index_B].longueur_linteau)
   			end
   			if ($index_A) 
  				@mur.objets[$index_A].longueur_linteau = (@mur.objets[$index_A].x_debut - @obj.x_fin).abs
  				@obj.longueur_linteau = @mur.objets[$index_A].longueur_linteau
  				puts(@mur.objets[$index_A].longueur_linteau)
  			end
			end   		
  		# cas des fenetres en bord de pignon
  		@obj.montage = montage
  		UI.messagebox(@obj.montage) if $DEBUG_FENETRE 
  		return montage
    end

    def recherche_obj_adjacent(element = @obj)
    	objets = @mur.objets
    	index_inf = index_sup = nil
    	objets.each do |obj|
    		distance_1 = element.x_debut - obj.x_fin
    		index_inf = @mur.objets.index(obj) if (distance_1 <= $long_pmb)&&(distance_1 > 0)
    		distance_2 = obj.x_debut - element.x_fin
    		index_sup = @mur.objets.index(obj) if (distance_2 <= $long_pmb)&&(distance_2 > 0)
    	end
    	return index_inf, index_sup
    end

    # add the window to the drawing
    def draw_obj(selection = @obj)
      vec = @fin - @debut
      vec.length = vec.length/2
      center = @debut + vec
      # puts "center = " + center.to_s
      selection.center_offset = (@mur.pt_debut.distance center).to_mm.round.to_i
      selection.x_debut = (selection.center_offset - selection.largeur/2.0)
      selection.x_fin = selection.center_offset + selection.largeur/2
      selection.montage = choix_montage_fenetre() if not (selection.montage =~/^\S$/)
      @mur.dimensions = "Sur mesure"
      @mur.ajouter_objet(selection)
      model = Sketchup.active_model
      model.start_operation("Ajoute Fenetre ou Porte")
      @mur.effacer_groupe
      @mur.draw
      model.commit_operation
    end
    
    def getExtents
        bb = Geom::BoundingBox.new
        if (@debut)
            bb.add(@debut)
            bb.add(@fin)
        else
            bb.add(@mur.pt_debut)
        end
        return bb
    end
    
    # draw a rectangular outline of the wall and window. Highlight the active
    # window
    def draw(view)
        # Show the current input point
        if (@ip.valid? && @ip.display?)
            @ip.draw(view)
            @drawn = true
        end 
    
        # draw the outline of the wall
        #puts("@mur.debut = #{@mur.pt_debut.inspect}")
        #puts("@mur.fin = #{@mur.pt_fin.inspect}")
        dessine_contour(view, @mur.pt_debut, @mur.pt_fin, @mur.largeur, @mur.justification, "DarkGray")
        vec = @fin - @debut
        # draw the outline of each door and window
        @mur.objets.each do |obj|
            vec.length = obj.center_offset - obj.largeur.mm/2.0
            obj_start = @mur.pt_debut + vec
            vec.length = obj.largeur.mm
            obj_end = obj_start + vec
            dessine_contour(view, obj_start, obj_end, @mur.largeur, @mur.justification, "DarkGray")
        end
        dessine_contour(view, @debut, @fin, @mur.largeur, @mur.justification, "Orange", 2)
        @drawn = true
    end
  
  end # Class Outils_Fenetre

end # module PMB