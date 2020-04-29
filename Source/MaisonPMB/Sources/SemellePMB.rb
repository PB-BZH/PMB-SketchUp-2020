module PMB
  class Semelle_betonPMB < Base_PMB
    attr_reader :objets
    
    $retrait = "10"
    
    def initialize(options={})
      options_semelle = {
        'nom'           =>'',
        'type_bloc'     => 'Standard',
        'element'       => 'Semelle',
        'long_sem'      => "0",
        'larg_sem'      => "400",
        'haut_sem'      => "250",
        'pt_debut'      => Geom::Point3d.new,
        'pt_fin'        => Geom::Point3d.new,
        'justification' => nil,
        'larg_sb'       => "200",
        'haut_sb'       => "500",
        'calque'        => "Fondations",
      }
      applique_options_globales(options_semelle)
      options_semelle.update(options)
      super(options_semelle)
      @objets = []
      if (nom.length == 0)
        nom = Base_PMB.nom_unique("Semelle")
      end
    end
    
    def options_semelle()
      semelle_PMB = [
        # prompt, attr_name, value, enums
        # parametres des briques PMB
        # --------------------------
        ["Type de semelle","Semelle_betonPMB.type_bloc","Standard"],
        ["Largeur soubassement","Semelle_betonPMB.larg_sb",nil],
        ["Hauteur soubassement","Semelle_betonPMB.haut_sb",nil],
        ["Largeur de semelle","Semelle_betonPMB.larg_sem",nil],
        ["Hauteur de semelle","Semelle_betonPMB.haut_sem",nil],
      ].freeze
      results = display_dialog("Dimension semelle beton en mm", self, semelle_PMB)
      return false if not results
    end
    
    def dessine_semelle(pt)
      points = dessin_profil()
      groupe = draw(pt,points)
      return groupe
    end # dessine_semelle
  
    def draw(pt,points)
      semelle_PMB = creer_groupe(semelle_PMB, "SemellePMB", $Texture_beton)
      face = semelle_PMB.entities.add_face points
      face.pushpull (long_sem.to_i - 2*$retrait.to_i).mm
      semelle_PMB = semelle_PMB.transform!(pt)
      return semelle_PMB
    end

    def dessin_profil()
      #     a  __ h
      #       |  |
      #       |  |
      #       |  |
      #   b  _|  |_ g
      #   c |      | f
      #     |      |
      #   d |______| e
      
      retrait  = $retrait.to_i.mm 
      larg_sb  = larg_sb.to_i.mm
      haut_sb  = haut_sb.to_i.mm
      haut_sem = haut_sem.to_i.mm
      ecart    = (larg_sem - larg_sb)/2 
      pts = []
      pts[0] = [retrait, retrait, 0]  # point a
      pts[7] = [retrait, retrait + larg_sb, 0]  # point h
      pts[6] = [retrait, retrait + larg_sb, -haut_sb] # point g
      pts[5] = [retrait, retrait + larg_sb + ecart, -haut_sb] # point f
      pts[4] = [retrait, retrait + larg_sb + ecart, -haut_sb - haut_sem] # point e
      pts[3] = [retrait, retrait - ecart, -haut_sb - haut_sem] # point d
      pts[2] = [retrait, retrait - ecart, -haut_sb] # point c
      pts[1] = [retrait, retrait, -haut_sb] # point b      
      return pts
    end
 end # class Bloc_PMB
  
end # module PMB