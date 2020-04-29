module PMB
#------------------------------------------------------------------------------------------
  class Outils_Mur < Outils_Fenetre
  # --------------- Outil MURS ----------------------------------------
  # Cette classe est utilisée pour dessiner un mur. Elle doit afficher
  # une boîte de dialogue  et permettre de dessiner un ou plusieurs 
  # murs utilisant ces propriétés. 
  # Appuyer sur Echap pour sortir de l'outils
  # -------------------------------------------------------------------
    
    PROPRIETES = [
      # prompt, attr_name, enums
      ["Justification des murs", "justification", "Gauche|Centre|Droite"],
      ["Dimensionnement","dimensions","Standard|Sur mesure"],
      ["Hauteur du mur", "hauteur", nil],
      ["Largeur du mur", "Mur.largeur", "190|140|110|100|70"],
      ["Type de mur", "Mur.style", "Ext|Refend"],
    ].freeze

    def initialize (options={})
      @mur = Mur.new()
      @mur.options_Murs()
    end
    
    def activate
      puts("Outils mur activé") if $VERBOSE
      calques = Sketchup.active_model.layers
      calque_epure = calques[@mur.calque + "_epure"]
      if not calque_epure
        ajoute_calque(@mur.calque + "_epure",true)
        calque_epure = calques[@mur.calque + "_epure"]
      end
      calque_epure.visible = true if not calque_epure.visible?
      @ip1 = Sketchup::InputPoint.new
      @ip = Sketchup::InputPoint.new
      self.reset
    end
    
    def deactivate(view)
      calques = Sketchup.active_model.layers
      calque_epure = calques[@mur.calque + "_epure"]
      calque_epure.visible = false if calque_epure.visible?
      view.invalidate if @drawn
      @ip1 = nil
      self.reset
      puts "Outils mur désactivé" if $VERBOSE
    end

    def reset
      @pts = []
      @state = STATE_PICK
      Sketchup::set_status_text " Conception PMB  ",SB_VCB_LABEL
      Sketchup::set_status_text " Dessin des murs ",SB_VCB_VALUE
      Sketchup::set_status_text %Q/ --> Selectionner les extrêmités du mur à contruire. [OPTIONS:]/+ 
                                %Q/ --> "F12" ou "CLIC DROIT" : Paramètres,/+
                                %Q/ --> "Echap" : Quitter/
      @drawn = false
    end
  
    def onKeyDown(key, repeat, flags,view)
      @mur.options_Murs() if (key==123)     # Touche F12
      @mur.nettoie_elements() if (key==121) # Touche F10
    end
    
    def onCancel(flag, view)
      puts "on cancel" if $VERBOSE
      view.invalidate if @drawn
      reset
      Sketchup.active_model.select_tool(nil)
    end
    
    def onMouseMove(flags, x, y, view)
      self.set_current_point(x, y, view)
    end
    
    def onLButtonDown(flags, x, y, view)
      self.set_current_point(x, y, view)
      self.update_state(view)
    end
    
    def onRButtonDown(flags, x, y, view)
      @mur.options_Murs()
    end

    # figure out where the user clicked and add it to the @pts array
    def set_current_point(x, y, view)
      if (!@ip.pick(view, x, y, @ip1))
        return false
      end
      #puts("attente d'un premier point")
      need_draw = true
      
      # Set the tooltip that will be displayed
      view.tooltip = @ip.tooltip
          
      # Compute points
      case @state
      when STATE_PICK # STATE_PICK = 1
        @pts[0] = @ip.position
        puts(@pts[0].inspect) if $VERBOSE
        need_draw = @ip.display? || @drawn
      when STATE_PICK_NEXT # STATE_PICK_NEXT = 2 
        @pts[1] = @ip.position 
        puts(@pts[1].inspect) if $VERBOSE
        @length = @pts[0].distance @pts[1]
        Sketchup::set_status_text(@length.to_s, SB_VCB_VALUE)
      end
  
      view.invalidate if need_draw
    end
    
    # créer un mur dans le dessin
    def dessine_mur
      mur_1 = @mur.clone
      mur_1.nom = PMB::Base_PMB.nom_unique("mur")
      mur_1.pt_debut = @pts[0]
      mur_1.pt_fin = @pts[1]
      mur_1.longueur = (@pts[0].distance(@pts[1])).to_mm.round
      puts mur_1.inspect if $VERBOSE
      vec = @pts[0].vector_to(@pts[1])
      puts "vec = " + vec.inspect if $VERBOSE
      if (vec.x.abs > 0)
        a1 = Math.atan2(vec.y, vec.x).radians 
        mur_1.angle = a1 - 90
        puts "vec = (" + vec.x.to_s + ", " + vec.y.to_s + ") a1 = " + a1.to_s if $VERBOSE
      else
        if (vec.y > 0)
          mur_1.angle = 0
        else
          mur_1.angle = 180
        end
      end
      puts "draw wall from " + @pts[0].to_s + " to " + @pts[1].to_s + " angle " + mur_1.angle.to_s if $VERBOSE
      Sketchup.active_model.start_operation("Ajoute le mur #{mur_1.nom}")
      group, skin_group = mur_1.draw
      Sketchup.active_model.commit_operation
    end
    
    # mise à jour de l'état clic souris
    def update_state(view)
      case @state
        when STATE_PICK
          @ip1.copy! @ip
          Sketchup::set_status_text "[Mur] Cliquer pour terminer le mur"
          Sketchup::set_status_text "Longueur", SB_VCB_LABEL
          Sketchup::set_status_text "", SB_VCB_VALUE
          @state = STATE_PICK_NEXT
        when STATE_PICK_NEXT
          self.dessine_mur
          view.invalidate if @drawn
          reset
          Sketchup.active_model.select_tool(nil)
      end
    end
    
    # if the user types in a number, use as the length of the wall
    def onUserText(text, view)
      # The user may type in something that we can't parse as a length
      # so we set up some exception handling to trap that
      begin
        value = text.to_l
      rescue
        # Error parsing the text
        UI.beep
        value = nil
        Sketchup::set_status_text "", SB_VCB_VALUE
      end
      return if !value
      
      if (@state == STATE_PICK_NEXT)
        # update the length of the wall
        vec = @pts[1] - @pts[0]
        #puts("vec.length = #{vec.length.m}")
        if( vec.length > 0.0 )
          vec.length = value
          @pts[1] = @pts[0].offset(vec)
          view.invalidate
          self.update_state(view)
        end
      end
    end
    
    def getExtents
        #puts "getExtents state = #{@state}"
        bb = Geom::BoundingBox.new
        if (@state == STATE_PICK)
            # We are getting the first point
            if (@ip.valid? && @ip.display?)
                bb.add(@ip.position)
            end
        else
            bb.add(@pts)
        end
        bb
    end
    
    # dessine un rectangle à la base du mur
    def draw(vue)
      #puts "draw state = #{@state}"
      # indique le point courant
      if (@ip.valid? && @ip.display?)
        #puts("test passé")
        @ip.draw(vue)
        @drawn = true
      end
    
      # Représente le contour de base du mur
      # ------------------------------------
      if (@state == STATE_PICK_NEXT)
        (@offset_pt0, @offset_pt1) = dessine_contour(vue, @pts[0], @pts[1], @mur.largeur, @mur.justification, "DarkGray", 2)
        @drawn = true
      end
    end
  
  end #class Outils_Mur
  # --------------- Fin Outil MURS -----------------------------------
end # module PMB