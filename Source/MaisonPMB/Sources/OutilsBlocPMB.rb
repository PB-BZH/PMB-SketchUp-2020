module PMB
#------------------------------------------------------------------------------------------
  class OutilsBlocPMB
  # --------------- Outil MURS --------------------------------------
  # Cette classe est utilisée pour dessiner des bloc PMB. Elle doit 
  # afficher une boîte de dialogue et permettre de dessiner un ou plusieurs 
  # bloc en utilisant ces propriétés. 
  # Appuyer sur Echap pour sortir de l'outils
  # -------------------------------------------------------------------
      
    def initialize(options={})
      @bloc = Bloc_PMB.new()
      #@bloc.options_Bloc_PMB()
    end

    def activate()
      puts("Outils bloc PMB activé") if $VERBOSE
      @ip1 = Sketchup::InputPoint.new
      @ip = Sketchup::InputPoint.new
      self.reset
    end
          
    def deactivate(view)
      puts("Outils bloc PMB désactivé") if $VERBOSE
      @ip1 = nil
      self.reset
    end

    def reset
      @pts = []
      @state = STATE_PICK
      Sketchup::set_status_text "    Maison PMB     ",SB_VCB_LABEL
      Sketchup::set_status_text "    Briques PMB    ",SB_VCB_VALUE
      Sketchup::set_status_text %Q/ [OPTIONS:]  --> "F12" ou "CLIC DROIT" : Paramètres PMB; --> "Echap" pour quitter/
    end

    def onCancel(flag, view)
      puts "Abandon" if $VERBOSE
      Sketchup.active_model.select_tool(nil)
    end
    
    def onKeyDown(key, repeat, flags,view)
      @bloc.options_Bloc_PMB() if (key==123)
    end
    
    def onRButtonDown(flags, x, y, view)
      @bloc.options_Bloc_PMB()
    end

    def onLButtonDown(flags, x, y, view)
      #self.set_current_point(x, y, view)
      @bloc.pt_debut = @ip.position
      @bloc.pmb_bloc(@bloc.pt_debut)
    end

    def onMouseMove(flags, x, y, view)
      self.set_current_point(x, y, view)
    end
    
    # figure out where the user clicked and add it to the @pts array
    def set_current_point(x, y, view)
      if (!@ip.pick(view, x, y, @ip1))
        return false
      end
    end
  end # class OutilsBlocPMB
#------------------------------------------------------------------------------------------
end # module PMB
#------------------------------------------------------------------------------------------
