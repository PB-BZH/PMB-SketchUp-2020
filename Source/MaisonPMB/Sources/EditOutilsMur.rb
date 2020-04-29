module PMB
  #------------------------- Outils d'edition des murs ------------------------------------
  
  # Edition des murs. Initialiser cet outil par un clic droit sur un mur. Ensuite, un clic
  # doit affiche le menu contextuel:
  #    Modifie les propriétés - change les propriétés du mur (comme l'épaisseur)
  #    Ajoute porte - ajoute une nouvelle porte au mur
  #    Déplace - permet de saisir le côté du mur pour dépasser le mur. Prenez un coin
  #              pour le faire tourner ou l'étirer.
  #--------------------------------------------------- ------------------------------------
  class Edit_Outils_Mur
  attr_accessor :mur, :groupe, :groupe_epure, :etat, :changement

    def initialize(mur)
      puts "Initialiation des outils d'édition du mur" if $VERBOSE
      @etat = STATE_EDIT
      @drawn = false
      @selection = nil
      @pt_a_deplacer = nil
      @changement = false
      @mur = mur
      
      # Make sure that there is really a wall selected
      if (not (defined?(@groupe) && defined?(@mur)))
        groupe = Edit_Outils_Mur.recherche_selection_mur()
        nom = groupe.get_attribute('Info élément', 'nom')
        if (nom =~ /epure/)
          nom.sub!('_epure', '')
          @groupe = Base_PMB.recherche_nom_entite(nom)
          @groupe_epure = groupe
        else
          @groupe = groupe
          @groupe_epure = Base_PMB.recherche_nom_entite(nom + "_epure")
        end
        
        @mur = creation_mur_pour_dessin(@groupe)
        
        if (not @mur)
          Sketchup.active_model.select_tool nil
          return
        end
      end
      
      # Get the end points
      # puts "mur = " + @mur.inspect
      @pts = [@mur.pt_debut, @mur.pt_fin]
      
    
      if (not @pts)
        UI.beep
        Sketchup.active_model.select_tool(nil)
        return
      end
      reset
    end
    
    def activate
      @groupe.hidden = true
      @groupe_epure.hidden = true if @groupe_epure
      @pts = [ @mur.pt_debut, @mur.pt_fin ]
      @ip = Sketchup::InputPoint.new
      reset
    end
    
    def reset
      Sketchup::set_status_text "", SB_VCB_LABEL
      Sketchup::set_status_text "", SB_VCB_VALUE
      Sketchup::set_status_text "[Edition du mur] Faire apparaître le menu par un clic droit sur le mur"
    end
    
    def deactivate(view)
      affiche_calque(@mur.calque + "_epure",false)
      view.invalidate if @drawn
      @ip = nil
      Sketchup.active_model.select_tool(nil)
    end
    
    def resume(view)
      @drawn = false
    end
    
    # figure out if the user has picked a side or a corner
    def chercher_point_a_deplacer(x, y, view)
      return false if not @coins
      ancien_pt_a_deplacer = @pt_a_deplacer
      ph = view.pick_helper(x, y)
      # puts "corners = " + @corners.inspect
      @selection = ph.pick_segment(@coins)
      # puts "selection = " + @selection.to_s
      if (@selection)
        if (@selection < 0)
          # We got a point on a segment.  Compute the point closest
          # to the pick ray.
          pickray = view.pickray(x, y)
          i = -@selection
          segment = [@coins[i-1], @coins[i]]
          result = Geom.closest_points(segment, pickray)
          @pt_a_deplacer = result[0]
          # if the user grabs and end segment, move the corner
          if (@selection == -2)
            @selection = 2
            @pt_a_deplacer = @pts[1]
          end
          if (@selection == -4)
            @selection = 1
            @pt_a_deplacer = @pts[0]
          end
        else
          # we got a control point
          @pt_a_deplacer = @coins[@selection]
        end
        @pt_de_depart = Sketchup::InputPoint.new(@pt_a_deplacer)
      else
        @pt_a_deplacer = nil
      end
      return ancien_pt_a_deplacer != @pt_a_deplacer
    end
    
    # determine if the point is inside of a window or door
    def rechercher_selection_objets(x, y, view)
      puts("rechercher_selection_objets 1") 
      return nil if not @coins
      puts("rechercher_selection_objets 2") 
      pickray = view.pickray(x, y)
      base_mur = [ @coins[0], $axe_Z ]
      pt_origine = Geom::intersect_line_plane(pickray, wall_base_plane)
      return nil if not pt_origine
      point = Geom::Point3d.new(pt_origine)
      # create a transformation if wall angle is not zero
      rotation_transformation = Geom::Transformation.rotation(@corners[0], Z_AXIS, -@mur.angle.degrees)
         
      debut_mur = Geom::Point3d.new(@mur.pt_debut)
      fin_mur = Geom::Point3d.new(@mur.pt_fin)
      if (@mur.angle != 0)
        debut_mur.transform!(rotation_transformation)
        fin_mur.transform!(rotation_transformation)
        point.transform!(rotation_transformation)
      end
      
      vec_mur = fin_mur - debut_mur
      
      @mur.objets.each do |obj|
        
        # find the four corners of the object
        vec_mur.length = (obj.center_offset - obj.largeur/2.0).mm
        debut_obj = debut_mur + vec_mur
        vec_mur.length = obj.largeur.mm
        fin_obj = debut_obj + vec_mur
        vec_obj = fin_obj - debut_obj
        next if (vec_obj.length <= 0)
        case @mur.justification
      when "Gauche"
        transform = Geom::Transformation.new(debut_obj, $axe_Z, 90.degrees)
      when "Droite"
        transform = Geom::Transformation.new(debut_obj, $axe_Z, (-90).degrees)
      when "Centre"
        transform = Geom::Transformation.new(debut_obj, $axe_Z, (0).degrees)
      else
        transform = Geom::Transformation.new
        UI.messagebox "Justification non valide"
      end   
        
      vec_obj.transform!(transform)
      vec_obj.length = @mur.largeur.mm
        offset_debut_obj = offset_debut_obj(vec_obj)
    
        # determine if the point lies within the rectangle
        # puts "orig_point = " + orig_point.inspect        
        # puts "point = " + point.inspect
        # puts "obj_start = " + obj_start.inspect
        # puts "obj_end = " + obj_end.inspect
        # puts "obj_start_offset = " + obj_start_offset.inspect
        if ((point.y > min(debut_obj.y, fin_obj.y)) &&
          (point.y < max(debut_obj.y, fin_obj.y)) &&
          (point.x > min(debut_obj.x, offset_debut_obj.x)) &&
          (point.x < max(debut_obj.x, offset_debut_obj.x)))
          # puts "found"
          view.invalidate
          return(obj)
        end
      end
      return(nil)    # didn't find a door or window under the mouse
    end
    
    def onLButtonDown(flags, x, y, view)
      case @etat
      when STATE_PICK
        # Select the segment or control point to move
        self.chercher_point_a_deplacer(x, y, view)
        @etat = STATE_MOVING if (@selection)
        Sketchup::set_status_text "distance", SB_VCB_LABEL
        Sketchup::set_status_text "", SB_VCB_VALUE
        Sketchup::set_status_text "[DEPLACEMENT DU MUR] Faites glisser mur vers le nouvel emplacement"
        @mouvement = false
        @changement = true
      when STATE_MOVING
        # ne rien faire
      when STATE_SELECT
        edit_objet(@selection_obj) if @selection_obj
        @etat = STATE_EDIT
      end
      
    end
    
    def onLButtonUp(flags, x, y, view)
      # we are finished moving, go back to edit state
      if ((@etat == STATE_MOVING) and @mouvement)
        draw(view)
        faire
      end
    end
    
    def onMouseMove(flags, x, y, view)
      @ip.pick(view, x, y)
      view.tooltip = @ip.tooltip if @ip.valid?
      @mouvement = true
      
      # Move the selected point if state = MOVING
      if (@etat == STATE_MOVING && @selection)
        @ip.pick(view, x, y, @pt_de_depart)
        view.tooltip = @ip.tooltip if @ip.valid?
        return if not @ip.valid?
        pt = @ip.position
        vec = pt - @pt_a_deplacer
        @pt_a_deplacer = pt
        deplace_point(vec)
        length = pt.distance @pt_de_depart.position
        Sketchup::set_status_text(length.to_s, SB_VCB_VALUE)
      elsif (@etat == STATE_PICK)
        # See if we can select something to move
        self.chercher_point_a_deplacer(x, y, view)
      elsif (@etat == STATE_SELECT)
        # highlight the selected object
        @selection_obj = rechercher_selection_objets(x, y, view) 
      end
      view.invalidate
    end
    
    def onCancel(flag, view)
      view.invalidate if @drawn
      if (@etat == STATE_MOVING)
        @etat = STATE_EDIT
        ancien_vec =  @pt_de_depart.position - @pt_a_deplacer
        deplace_point(ancien_vec)
      end
      @changed = false;
      faire
    end
    
    # move the object endpoints the distance specified by the 
    # length of the vector
    def deplace_point(vec)
      if (@selection >= 0)
        # Moving a control point
        if ((@selection == 0) or (@selection == 3))
          @pts[0].offset!(vec)
        else
          @pts[1].offset!(vec)
        end
      else
        # moving a segment
        @pts[0].offset!(vec)
        @pts[1].offset!(vec)          
      end
    end
    
    def faire
      if (@changement)
        dessine_mur()
      else
        @groupe.hidden = false;
        @groupe_epure.hidden = false if (@groupe_epure)
      end
      Sketchup.active_model.select_tool nil
    end
    
    # redraw the wall at the new position
    def dessine_mur
      @mur.pt_debut = @pts[0]
      @mur.longueur = (@pts[0].distance(@pts[1])).to_mm.round
      @mur.dimensions = "Sur mesure"
      @mur.mont_imp = true
      
      
      vec = @pts[0].vector_to(@pts[1])
      puts "vec = (" + vec.x.to_s + ", " + vec.y.to_s if $VERBOSE
      if (vec.x.abs > 0.01)
        a1 = Math.atan2(vec.y, vec.x).radians 
        @mur.angle = a1 - 90
        puts "a1 = " + a1.to_s if $VERBOSE
      else
        if (vec.y > 0)
          @mur.angle = 0
        else
          @mur.angle = 180
        end
      end
      puts "draw wall from " + @pts[0].to_s + " to " + @pts[1].to_s + " angle " + @mur.angle.to_s if $VERBOSE
      @groupe.erase!
      @groupe_epure.erase! if (@groupe_epure)
      
      modele = Sketchup.active_model
      modele.start_operation "Dessine le mur"
      @groupe, @groupe_epure = @mur.draw
      modele.commit_operation
        
      @changement = false
    end
    
    # edit a door or window
    def edit_objet(obj)
      puts "edit objet #{obj}" if $VERBOSE
      Sketchup.active_model.select_tool Edit_Outils_Mur.new(self, obj)
    end
    
    def self.affiche_propriete_mur()
      tool = Edit_Outils_Mur.new(nil)
      if (tool.mur.class.to_s =="PMB::Pignon")
        results = tool.mur.options_Pignons()
      else
        results = tool.mur.options_Murs()
      end
      #puts(results.inspect)
      if (results)
        tool.changement = true
        tool.faire
      end
    end
    
    def self.deplace_mur
      tool = Edit_Outils_Mur.new(nil)
      tool.etat = STATE_PICK
      Sketchup.active_model.select_tool(tool)
    end
    
    def self.efface_mur
      outil = Edit_Outils_Mur.new(nil)
      result = UI.messagebox("Effacer ce mur: #{outil.mur.nom} ?" , MB_YESNO, "Supprimer")
      if (result == 6)
        outil.groupe.erase!
        outil.groupe_epure.erase! if (outil.groupe_epure)
      end
      Sketchup.active_model.select_tool(nil)
    end

    def getExtents
      bb = Geom::BoundingBox.new
      bb.add @pts
      bb
    end
    
    def draw(view)
      @coins = [] if not defined?(@coins)
      @coins[0] = @pts[0]
      @coins[1] = @pts[1]
      (a, b) = dessine_contour(view, @mur.pt_debut, @mur.pt_fin, @mur.largeur, @mur.justification, "DarkGray", 2)
      # puts "a = " + a.inspect
      @coins[2] = b
      @coins[3] = a
      @coins[4] = @pts[0]
      vec = @pts[1] - @pts[0]
      @mur.objets.each do |obj|
        vec.length = (obj.center_offset - obj.largeur/2.0).mm
        debut_obj = @mur.pt_debut + vec
        vec.length = obj.largeur.mm
        fin_obj = debut_obj + vec
        if (defined?(@selection_obj) && (obj == @selection_obj))
          dessine_contour(view, debut_obj, fin_obj, @mur.largeur, @mur.justification, "red", 3)
        else
          dessine_contour(view, debut_obj, fin_obj, @mur.largeur, @mur.justification, "gray")
        end
      end
      
      if ((@etat == STATE_PICK) || (@etat == STATE_MOVING))
        if (@pt_a_deplacer)
          view.draw_points(@pt_a_deplacer, 10, 2, "red");
        end
        if (@etat == STATE_MOVING)
         view.set_color_from_line(@pt_de_depart.position, @pt_a_deplacer)
         view.line_stipple = "."    # dotted line
         view.draw(GL_LINE_STRIP, @pt_de_depart.position, @pt_a_deplacer)
        end
      end
      
      @drawn = true
    end
    
    def self.recherche_selection_mur
      ss = Sketchup.active_model.selection
      groupe = ss.first
      if (groupe.kind_of?(Sketchup::Group))
        type_mur = groupe.get_attribute("Info élément", "element")
        case type_mur
        when "Mur", "Pignon", "rakewall"
          return groupe
        end
      end
      # pas de mur selectionné
      UI.beep
      return nil
    end
    
    def self.editer_mur
      mur = Edit_Outils_Mur.recherche_selection_mur
      Sketchup.active_model.select_tool Edit_Outils_Mur.new(mur)
    end
  end # class EditWallTool
end #Modeule PMB