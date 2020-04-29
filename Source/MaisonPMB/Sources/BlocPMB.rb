module PMB
  class Bloc_PMB < Base_PMB
    attr_reader :objets
    
    def initialize(options={})
      option_blocs = {
        'nom'         => '',
        'type_bloc'   => 'Standard',
        'style'       => 'Refend',
        'dimensions'  => 'Standard',
        'long_bloc'   => 600,
        'long_spec'   => 0,
        'largeur'     => 0,
        'angle_style' => nil,
        'hauteur'     => 85,
        'long_linteau'=> 3000,
        'chanfrein'   => 10,
        'pt_debut'    => Geom::Point3d.new,
        'calque'      => '',
      }
      applique_options_globales(option_blocs)
      option_blocs.update(options)
      super(option_blocs)
      @objets = []
      if (self.nom.length == 0)
        self.nom = Base_PMB.nom_unique("bloc PMB")
      end
    end
    
    def options_Bloc_PMB()
      blocs_PMB = [
        # parametres des briques PMB
        # --------------------------
        $Type_Bloc,
        $Style_Bloc,
        $Largeur_Bloc,
        $long_linteau,
        $style_angle,
      ].freeze
      results = affiche_dialogue("Propriétés des blocs PMB", self, blocs_PMB)
      return false if not results
      return results
    end

    def longueur(objet_bloc = self)
      if (dimensions != 'Sur mesure')
        case (objet_bloc.type_bloc)
        when 'Standard'
          return objet_bloc.long_bloc
        when 'Demi'
          return (objet_bloc.long_bloc / 2.0)
        when 'Angle'
          return (objet_bloc.long_bloc / 2.0 + objet_bloc.largeur)
        end
      else
        return objet_bloc.long_spec
      end
    end

    $times = nil
      
    def pmb_bloc(pt)
      options_Bloc_PMB() if (largeur == 0)
      case (self.style)
        when 'Refend'
          points = dessin_profil_refend()
        when 'Ext'
          points = dessin_profil_ext()
        else
          UI.messagebox("Style de bloc non communiqué")
          return false
      end      
      grp = draw(pt,points)
      return grp
    end

    def draw(pt,points)
      bloc_PMB = creer_groupe()
      face = bloc_PMB.entities.add_face(points.collect {|p| p.transform(pt)})
      face.pushpull(self.longueur.mm, true)
      return bloc_PMB
    end
    
    def dessin_profil_refend()
      larg = self.largeur.mm
      haut = self.hauteur.mm
      pts = []
      pts[0] = Geom::Point3d.new(0, 0, 0);
      pts[1] = Geom::Point3d.new(0, larg, 0);
      pts[2] = Geom::Point3d.new(0, larg, haut);
      pts[3] = Geom::Point3d.new(0, 0, haut);
      return pts
    end

    def dessin_profil_ext()
      larg = self.largeur.mm
      haut = self.hauteur.mm
      chfr = self.chanfrein.mm
      pts = []
      pts[0] = Geom::Point3d.new(ORIGIN) ;
      pts[1] = Geom::Point3d.new(0, larg, 0);
      pts[2] = Geom::Point3d.new(0, larg, haut);
      pts[3] = Geom::Point3d.new(0, chfr, haut);
      pts[4] = Geom::Point3d.new(0, 0, haut-chfr);
      return pts
    end
 end # class Bloc_PMB
  
end # module PMB
