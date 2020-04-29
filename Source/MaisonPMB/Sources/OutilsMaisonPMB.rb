require 'sketchup.rb'
require 'MaisonPMB/sources/MaisonPMB.rb'

# Constantes définissant les trois ases du repère
# -----------------------------------------------
$axe_X = Geom::Vector3d.new 1,0,0
$axe_Y = Geom::Vector3d.new 0,1,0
$axe_Z = Geom::Vector3d.new 0,0,1

# Constantes de construction
# --------------------------
MUR_MIN = 790

# Ce sont les états dans lesquels un outil peut être
# --------------------------------------------------
STATE_EDIT = 0 if not defined? STATE_EDIT
STATE_PICK = 1 if not defined? STATE_PICK
STATE_PICK_NEXT = 2 if not defined? STATE_PICK_NEXT
STATE_PICK_LAST = 3 if not defined? STATE_PICK_LAST
STATE_MOVING = 4 if not defined? STATE_MOVING
STATE_SELECT = 5 if not defined? STATE_SELECT

def min(x, y)
  if (x < y)
    return x
  end
  return y
end

def max(x, y)
  if (x > y)
    return x
  end
  return y
end

# Permet de creer un groupe Skectchup posssedant une texture. renvoie le groupe
def creer_groupe(nom_groupe="bloc_PMB")
  groupe = Sketchup.active_model.active_entities.add_group()
  return groupe
end

def ajoute_calque(nom_calque,visible=false)
  # Création d'un nouveau calque
  calques = Sketchup.active_model.layers
  return false if (calques[nom_calque])
  calque = calques.add(nom_calque)
  calque.visible = visible
  return true
end

def change_calque_actif(nom_calque,visible=true)
  # Change de calque actif
  calques = Sketchup.active_model.layers
  ancien_calque = Sketchup.active_model.active_layer
  ancien_nom = Sketchup.active_model.active_layer.name
  nouveau_calque = calques[nom_calque]
  nouveau_calque = calques.add(nom_calque) if not nouveau_calque
  Sketchup.active_model.active_layer = nouveau_calque
  calques[nom_calque].visible = visible 
  return ancien_nom
end

def affiche_calque(nom_calque,visible=true)
  # Change de calque actif et le rend visible ou non
  calques = Sketchup.active_model.layers
  calques[nom_calque].visible = visible 
end

# Affiche une boite dialogue de saisie et stocke le resultat dans un objet
def affiche_dialogue(title, obj, data)
  prompts = []
  attr_names = []
  values = []
  enums = []
  #puts("\nobj: #{obj.inspect}\n")
  data.each { |a| 
    #puts a.inspect
    a[1]=a[1].split(".")[1] if a[1].include?(".");
    prompts.push(a[0]);
    attr_names.push(a[1]);
    values.push(obj.send(a[1]));
    enums.push(a[2])
  }
  results = UI.inputbox(prompts, values, enums, title)
  if results
    i = 0
    attr_names.each do |nom|
      if (nom)
        #puts("obj.#{nom}")
        eval("obj.#{nom} = results[i]")
        #UI.messagebox ("obj =  + #{obj.inspect}")
      end
      i = i + 1
    end
  end
  return results
end

def affiche_dialogue_options_globales()
  parameters_PMB = [
    # prompt, attr_name, value, enums
    # parametres bes briques PMB
    # --------------------------
    # Murs
      ["Dimensionnement","dimensions","Standard|Sur mesure"],
      ["Hauteur du mur", "mur.hauteur", nil],
      ["Largeur du mur", "mur.largeur", "190|140|110|100|70"],
      ["Type de mur", "style", "Ext|Refend"],
      ["Justification des murs", "mur.justification", "Gauche|Centre|Droite"],
    # Pignons
	    [ "Pente en degrée", "pignon.pente", nil ],
		  [ "type de toit", 'pignon.type_toit', "1 pente __\\|1 pente /__|2 pentes /\\"],
    # Fenetres
      [ "Justification Fenêtre", "fenetre.justification", "Gauche|Centre|Droite" ],
      [ "Hauteur du linteau", "fenetre.hauteur_linteau", nil ],
      [ "largeur de la fenêtre", "fenetre.largeur", nil ],
      [ "Hauteur de la fenêtre", "fenetre.hauteur", nil ],
  ].freeze
  prompts = []
  attr_names = []
  values = []
  enums = []
  parameters_PMB.each { |a|
    prompts.push(a[0]);
    attr_names.push(a[1]);
    values.push(PMB::Base_PMB::PMB_OPTIONS_GLOBALES[a[1]]);
    enums.push(a[2])
  }
  results = UI.inputbox(prompts, values, enums, 'Proprietés globales')
  if results
    i = 0
    attr_names.each do |name|
      eval("PMB::Base_PMB::PMB_OPTIONS_GLOBALES['#{name}'] = results[i]")
      i = i + 1
    end
  end
  return results
end

# Dessine un rectangle 2D à la base du mur
# ----------------------------------------
def dessine_contour(vue, debut, fin, largeur, wall_justify, color, line_width=1)
   #dessine_contour(vue, @pts[0], @pts[1], @mur.largeur.mm, @mur.justification, "gray")
  # -------------------------------------------------
  #UI.messagebox("Stop dessine_contour")
  vue.set_color_from_line(debut, fin)
  vue.line_width = line_width
  vue.draw(GL_LINE_STRIP, debut, fin)
  vue.drawing_color = color

  # calculate the other points
  # create a perpendicular vector
  vec = fin - debut
  #puts ("Longueur vecteur => #{vec.length}")
  if (vec.length > 0)
    case wall_justify
      when "Gauche" 
        transform = Geom::Transformation.new(debut, [0, 0, 1], (90).degrees)
      when "Centre"
        transform = Geom::Transformation.new(debut, [0, 0, 1], 0.degrees)
      when "Droite"
        transform = Geom::Transformation.new(debut, [0, 0, 1], (-90).degrees)
      else
        UI.messagebox "invalid justification"
      end   
      
    vec.transform!(transform)
    vec.length = largeur.mm
    offset_debut = debut.offset(vec)
    offset_fin = fin.offset(vec)
    vue.draw(GL_LINE_STRIP, debut, offset_debut)
    vue.draw(GL_LINE_STRIP, offset_debut, offset_fin)
    vue.draw(GL_LINE_STRIP, offset_fin, fin)
  end
  return offset_debut, offset_fin
end

def creation_mur_pour_dessin(group)
  nom = group.get_attribute("Info élément", "nom")
  case group.get_attribute("Info élément", "element")
    when "Mur"
        mur = PMB::Mur.creation_pour_dessin(group) 
    when "Pignon" 
        mur = PMB::Pignon.creation_pour_dessin(group) 
    when "rakewall" 
        mur = PMB::Pignon.creation_pour_dessin(group) 
    else
        UI.messagebox "Mur de type inconnu !"
    end
  return mur
end
      
#------------------------------------------------------------------------------------------
module PMB
  # ---------- Classes Extérieures ------------------------------------
  require 'MaisonPMB/Sources/OutilsBlocPMB.rb'
  require 'MaisonPMB/Sources/OutilsMurPMB.rb'
  require 'MaisonPMB/Sources/EditOutilsMur.rb'
  require 'MaisonPMB/Sources/OuverturePMB.rb'
  require 'MaisonPMB/Sources/OutilsfenetrePMB.rb'
  require 'MaisonPMB/Sources/OutilsPignonPMB.rb'
  require 'MaisonPMB/Sources/nomenclature.rb'
  # -------------------------------------------------------------------
	  
end #module PMB  
#------------------------------------------------------------------------------------------
