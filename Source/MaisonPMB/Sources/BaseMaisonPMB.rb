module PMB
  class Base_PMB
    attr_accessor :table
    
    PMB_OPTIONS_GLOBALES ={
      'Bloc_PMB.type_bloc'  		=> 'Standard',
      'Bloc_PMB.longueur'   		=> 600,
      'Bloc_PMB.angle_style'		=> 'Gauche',
      'Bloc_PMB.hauteur'    		=> 85,
      'Bloc_PMB.chanfrein' 			=> 10,
      'style'        				=> 'Ext',
      'mur.largeur'         		=> 190,
      'mur.hauteur'         		=> 2550,
      'mur.justification'   		=> 'Gauche',
      'dimensions'		 			=> 'Standard',
      'pignon.pente'						=> 45,
      'pignon.type_toit'				=> "2 pentes /\\",
      'fenetre.justification'   => 'Gauche',
      'fenetre.hauteur_linteau' => 2210,
      'fenetre.largeur'         => 900,
      'fenetre.hauteur'         => 1360,
    } if not defined?(PMB_OPTIONS_GLOBALES)
 
    # initialize attributes
    def initialize(hash={})
      @table = {}
      if hash
        for k,v in hash
          @table[k.to_sym] = v
          nouveau_membre(k)
        end
      end
    end

    # allow direct access to option table as if they were attributes
    def nouveau_membre(name)
      unless self.respond_to?(name)
        self.instance_eval %{
          def #{name}; @table[:#{name}]; end
          def #{name}=(x); @table[:#{name}] = x; end
        }
      end
    end

    # update object hash table with applicable global options
    def applique_options_globales(hashtbl)
      classname = self.class.to_s.downcase
      PMB_OPTIONS_GLOBALES.keys.each do |key|
        parts = key.split('.')
        key_class = ''
        if (parts.length == 2)
          key_class = parts[0]
          next if not (classname =~ /#{key_class}/)
          newkey = parts[1]
        else
          newkey = key
          #puts("key = #{key}")
        end
        if (hashtbl.has_key?(newkey))
          hashtbl[newkey] = PMB_OPTIONS_GLOBALES[key]
          #puts("hashtbl[newkey] = #{hashtbl[newkey]}")
        end
      end
    end

    def self.recherche_nom_entite(cible, entite = Sketchup.active_model.entities)
      result = nil
      #puts "nombre d'éléments = " + entite.count.to_s
      entite.each do |ent|
          # only groups have names
          next if not (ent.kind_of?(Sketchup::Group))
        nom = ent.get_attribute('Info élément', 'nom')
        if (nom && (nom == cible))
          result = ent
          break
        end
        # recursively search groups for entities
        if (ent.entities != nil)
            result = Base_PMB.recherche_nom_entite(cible, ent.entities)
            break if (result)
        end
      end
      return result
    end
    
    def self.nom_unique(base)
      nom = ''
      0.upto(1000) do |i|
        nom = base + i.to_s
        if (Base_PMB.recherche_nom_entite(nom) == nil)
          #puts("Ne trouve pas ce nom")
          break
        end
      end
      #puts "nom unique : " + nom
      return nom
    end
    
    def recupere_option_dessin(grp)
      print "Option pour dessiner\n" if $VERBOSE
      table.keys.each do |cle|
        valeur = grp.get_attribute('Info élément', cle.to_s)
        if valeur
          table[cle] = valeur
          print cle.to_s + " = " + valeur.to_s + ",\n" if $VERBOSE
        end
      end
    end
    
    def sauve_options_dessin(grp)
      if ($VERBOSE)
        print "Sauvegarde des options pour dessiner : \n"
        table.keys.each { |cle| print cle.to_s + " = " + table[cle].to_s + ", \n"}
        puts
      end
      table.keys.each { |cle| grp.set_attribute('Info élément', cle.to_s, table[cle])}
    end

    def remplir_options(cles, extras)
        tableau_options = table.select { |cle, value| cles.include?(cle.to_s) }
        options = Hash.new
        tableau_options.each { |pair| options[pair[0].to_s] = pair[1] }
        options.update(extras)
        return options
    end
    
    def nettoie_elements(entite = Sketchup.active_model.entities)
      model = entite.model
      ancien_calque = model.active_layer
      count = entite.count
      groupe = []
      groupe.each do |e|
        type = e.get_attribute('Info élément','element') 
        if type == "Mur"
          mur = Mur.creation_dessin(e)
          model.active_layer = e.layer
          e.erase!
          mur.draw
        end
      end
      puts "nombre d'éléments avant = " + entite.count.to_s
      for i in 0..entite.count do
        entite.each do |ent|
          next if (ent.kind_of?(Sketchup::Group))
          ent.erase!
        end
      end
      puts "nombre d'éléments après= " + entite.count.to_s
      model.active_layer = ancien_calque
    end

    def corrige_hauteur(valeur)
      haut = ""
      choix = []
      nb_rang = (valeur / $haut_pmb).to_int
      haut_min = nb_rang * $haut_pmb
      haut_max = (nb_rang + 1) * $haut_pmb
      haut_mur = haut.split('|')
      haut_mur.push(haut_min.to_i)
      haut_mur.push(haut_max.to_i)
      haut = haut_mur.uniq.join('|')
      choix.push(haut)
      reponse = UI.inputbox(["Hauteur"], ["#{haut_min}"],choix, "Hauteur PMB adaptée") while !reponse
      valeur = reponse[0].to_i
      return valeur
    end
      
  end # class Base_PMB
  
  
end # module PMB
