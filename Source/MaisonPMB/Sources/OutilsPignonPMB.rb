module PMB
	class Outils_Pignon < Outils_Mur
		PROPERTIES = [
		    [ "Pente en degrée", "pente", nil ],
		    [ "type de toit", 'type_toit', "1 pente __\\|1 pente /__|2 pentes /\\|4 pentes" ],
		    [ "Justification  ", "justification", "Gauche|Centre|Droite" ],
		].freeze
		
		def initialize()
			@mur = PMB::Pignon.new() 
			@mur.options_Pignons()
		end

    def onRButtonDown(flags, x, y, view)
      @mur.options_Pignons()
    end

    def onKeyDown(key, repeat, flags,view)
      @mur.options_Pignons() if (key==123)     # Touche F12
    end

		
	end
end