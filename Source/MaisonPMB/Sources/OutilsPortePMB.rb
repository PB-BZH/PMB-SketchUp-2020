module PMB
  #--------  D O O R T O O L  ------------------------------------------------
  
  # Add a door to a wall. This tool displays a door property dialog and then 
  # allows the user to place the door using the mouse. Click the mouse when the
  # door is in the correct position.
  class Outils_Porte < Outils_Fenetre
  
    PROPRIETES = [
      # prompt, attr_name, value, enums
      [ "Justification des portes", "justification", "Gauche|Centre|Droite" ],
      [ "Hauteur du linteau", "hauteur_linteau", nil ],
      [ "largeur de la porte", "largeur", nil ],
      [ "Hauteur de la porte", "hauteur", nil ],
    ].freeze
         
    def initialize(groupe_mur)
      @obj = Porte.new()
      results = @obj.options_Portes()
      return false if not results
      @mur = creation_mur_pour_dessin(groupe_mur)
      @objtype = "Porte"
      reset
      return true
    end
    
    def reset
        super
        Sketchup::set_status_text "[Outils Portes] Utiliser la souris pour déplacer la porte; Cliquer pour la positionner"
    end
  
    def onRButtonDown(flags, x, y, view)
      @obj.options_Portes()
    end

    def onKeyDown(key, repeat, flags,view)
      @obj.options_Portes() if (key==123)     # Touche F12
    end

  end # class DoorTool
end