require 'sketchup.rb'
require 'MaisonPMB/sources/BaseMaisonPMB.rb'
require 'MaisonPMB/sources/blocPMB.rb'
require 'MaisonPMB/sources/SemellePMB.rb'
require 'MaisonPMB/sources/MurPMB.rb'
require 'MaisonPMB/sources/OuverturePMB.rb'
require 'MaisonPMB/sources/FenetrePMB.rb'
require 'MaisonPMB/sources/OutilsFenetrePMB.rb'
require 'MaisonPMB/sources/EditOuverturesMur.rb'
require 'MaisonPMB/sources/PortePMB.rb'
require 'MaisonPMB/sources/OutilsPortePMB.rb'
#require 'MaisonPMB/sources/OutilsPignonPMB.rb'
require 'MaisonPMB/sources/PignonPMB.rb'

# Run
def exec_on_autoload
  hb_read_sections_file
end

$long_pmb = 600
$long_pmb_demi = 300
$haut_pmb = 85

def hb_Apropos
  UI.messagebox("Construction Bois,\nParpaing Bois Massif\n\nProgrammation: PB_BZH CONCEPT, Fev 2011\n\n\t Patrick Bourges", MB_MULTILINE, "A propos")
end

def verifie_selection_mur
  mur = PMB::Edit_Outils_Mur.recherche_selection_mur
  return mur
end

def hb_read_sections_file
  $Style_Bloc = []
  $Longueur_Bloc = []
  $Largeur_Bloc = []
  $style_angle = []
  $Hauteur = []
  $long_linteau = []

  puts "Recuperation de la texture"
  $Texture_bois = Sketchup.find_support_file("Pin_d_Oregon.jpg", "Plugins/MaisonPMB/ressources/")
  $Texture_beton = Sketchup.find_support_file("Beton.jpg", "Plugins/MaisonPMB/ressources/")
  
  $PMB_190_stand_ext = Sketchup.find_support_file("pmb_190_stand_ext.skp", "Plugins/MaisonPMB/composants_pmb/190/")
  $PMB_190_demi_ext = Sketchup.find_support_file("pmb_190_demi_ext.skp", "Plugins/MaisonPMB/composants_pmb/190/")
  $PMB_190_angle_ext_droite = Sketchup.find_support_file("pmb_190_angle_ext_droite.skp", "Plugins/MaisonPMB/composants_pmb/190/")
  $PMB_190_angle_ext_gauche = Sketchup.find_support_file("pmb_190_angle_ext_gauche.skp", "Plugins/MaisonPMB/composants_pmb/190/")
  $PMB_190_angle_int_ext_droite = Sketchup.find_support_file("pmb_190_angle_int_ext_droite.skp", "Plugins/MaisonPMB/composants_pmb/190/")
  $PMB_190_angle_int_ext_gauche = Sketchup.find_support_file("pmb_190_angle_int_ext_gauche.skp", "Plugins/MaisonPMB/composants_pmb/190/")
  $PMB_190_stand_rfd = Sketchup.find_support_file("pmb_190_stand_rfd.skp", "Plugins/MaisonPMB/composants_pmb/190/")
  $PMB_190_demi_rfd = Sketchup.find_support_file("pmb_190_demi_rfd.skp", "Plugins/MaisonPMB/composants_pmb/190/")
  $PMB_190_angle_rfd = Sketchup.find_support_file("pmb_190_angle_rfd.skp", "Plugins/MaisonPMB/composants_pmb/190/")

  $PMB_140_stand_ext = Sketchup.find_support_file("pmb_140_stand_ext.skp", "Plugins/MaisonPMB/composants_pmb/140/")
  $PMB_140_demi_ext = Sketchup.find_support_file("pmb_140_demi_ext.skp", "Plugins/MaisonPMB/composants_pmb/140/")
  $PMB_140_angle_ext_droite = Sketchup.find_support_file("pmb_140_angle_ext_droite.skp", "Plugins/MaisonPMB/composants_pmb/140/")
  $PMB_140_angle_ext_gauche = Sketchup.find_support_file("pmb_140_angle_ext_gauche.skp", "Plugins/MaisonPMB/composants_pmb/140/")
  $PMB_140_angle_int_ext_droite = Sketchup.find_support_file("pmb_140_angle_int_ext_droite.skp", "Plugins/MaisonPMB/composants_pmb/140/")
  $PMB_140_angle_int_ext_gauche = Sketchup.find_support_file("pmb_140_angle_int_ext_gauche.skp", "Plugins/MaisonPMB/composants_pmb/140/")
  $PMB_140_stand_rfd = Sketchup.find_support_file("pmb_140_stand_rfd.skp", "Plugins/MaisonPMB/composants_pmb/140/")
  $PMB_140_demi_rfd = Sketchup.find_support_file("pmb_140_demi_rfd.skp", "Plugins/MaisonPMB/composants_pmb/140/")
  $PMB_140_angle_rfd = Sketchup.find_support_file("pmb_140_angle_rfd.skp", "Plugins/MaisonPMB/composants_pmb/140/")

  $PMB_110_stand_ext = Sketchup.find_support_file("pmb_110_stand_ext.skp", "Plugins/MaisonPMB/composants_pmb/110/")
  $PMB_110_demi_ext = Sketchup.find_support_file("pmb_110_demi_ext.skp", "Plugins/MaisonPMB/composants_pmb/110/")
  $PMB_110_angle_ext_droite = Sketchup.find_support_file("pmb_110_angle_ext_droite.skp", "Plugins/MaisonPMB/composants_pmb/110/")
  $PMB_110_angle_ext_gauche = Sketchup.find_support_file("pmb_110_angle_ext_gauche.skp", "Plugins/MaisonPMB/composants_pmb/110/")
  $PMB_110_angle_int_ext_droite = Sketchup.find_support_file("pmb_110_angle_int_ext_droite.skp", "Plugins/MaisonPMB/composants_pmb/110/")
  $PMB_110_angle_int_ext_gauche = Sketchup.find_support_file("pmb_110_angle_int_ext_gauche.skp", "Plugins/MaisonPMB/composants_pmb/110/")
  $PMB_110_stand_rfd = Sketchup.find_support_file("pmb_110_stand_rfd.skp", "Plugins/MaisonPMB/composants_pmb/110/")
  $PMB_110_demi_rfd = Sketchup.find_support_file("pmb_110_demi_rfd.skp", "Plugins/MaisonPMB/composants_pmb/110/")
  $PMB_110_angle_rfd = Sketchup.find_support_file("pmb_110_angle_rfd.skp", "Plugins/MaisonPMB/composants_pmb/110/")

  $PMB_100_stand_ext = Sketchup.find_support_file("pmb_100_stand_ext.skp", "Plugins/MaisonPMB/composants_pmb/100/")
  $PMB_100_demi_ext = Sketchup.find_support_file("pmb_100_demi_ext.skp", "Plugins/MaisonPMB/composants_pmb/100/")
  $PMB_100_angle_ext_droite = Sketchup.find_support_file("pmb_100_angle_ext_droite.skp", "Plugins/MaisonPMB/composants_pmb/100/")
  $PMB_100_angle_ext_gauche = Sketchup.find_support_file("pmb_100_angle_ext_gauche.skp", "Plugins/MaisonPMB/composants_pmb/100/")
  $PMB_100_angle_int_ext_droite = Sketchup.find_support_file("pmb_100_angle_int_ext_droite.skp", "Plugins/MaisonPMB/composants_pmb/100/")
  $PMB_100_angle_int_ext_gauche = Sketchup.find_support_file("pmb_100_angle_int_ext_gauche.skp", "Plugins/MaisonPMB/composants_pmb/100/")
  $PMB_100_stand_rfd = Sketchup.find_support_file("pmb_100_stand_rfd.skp", "Plugins/MaisonPMB/composants_pmb/100/")
  $PMB_100_demi_rfd = Sketchup.find_support_file("pmb_100_demi_rfd.skp", "Plugins/MaisonPMB/composants_pmb/100/")
  $PMB_100_angle_rfd = Sketchup.find_support_file("pmb_100_angle_rfd.skp", "Plugins/MaisonPMB/composants_pmb/100/")

  $PMB_70_stand_ext = Sketchup.find_support_file("pmb_70_stand_ext.skp", "Plugins/MaisonPMB/composants_pmb/70/")
  $PMB_70_demi_ext = Sketchup.find_support_file("pmb_70_demi_ext.skp", "Plugins/MaisonPMB/composants_pmb/70/")
  $PMB_70_angle_ext_droite = Sketchup.find_support_file("pmb_70_angle_ext_droite.skp", "Plugins/MaisonPMB/composants_pmb/70/")
  $PMB_70_angle_ext_gauche = Sketchup.find_support_file("pmb_70_angle_ext_gauche.skp", "Plugins/MaisonPMB/composants_pmb/70/")
  $PMB_70_angle_int_ext_droite = Sketchup.find_support_file("pmb_70_angle_int_ext_droite.skp", "Plugins/MaisonPMB/composants_pmb/70/")
  $PMB_70_angle_int_ext_gauche = Sketchup.find_support_file("pmb_70_angle_int_ext_gauche.skp", "Plugins/MaisonPMB/composants_pmb/70/")
  $PMB_70_stand_rfd = Sketchup.find_support_file("pmb_70_stand_rfd.skp", "Plugins/MaisonPMB/composants_pmb/70/")
  $PMB_70_demi_rfd = Sketchup.find_support_file("pmb_70_demi_rfd.skp", "Plugins/MaisonPMB/composants_pmb/70/")
  $PMB_70_angle_rfd = Sketchup.find_support_file("pmb_70_angle_rfd.skp", "Plugins/MaisonPMB/composants_pmb/70/")

  puts "Reading sections file"
  $PMB_Support_file = Sketchup.find_support_file("PMB_sections.txt", "Plugins/MaisonPMB/ressources/")
  $sections = IO.readlines($PMB_Support_file)
  # Parpaing bois massif: PMB
  # ---------------------------------------------
  type_PMB = $sections[1].chop.split(" ")
  style_PMB = $sections[2].chop.split(" ")
  longueur_PMB = $sections[3].chop.split(" ")
  largeur_PMB = $sections[4].chop.split(" ")
  style_angle = $sections[5].chop.split(" ")
  hauteur_PMB = $sections[6].chop.split(" ")
  longueur_linteau_PMB = $sections[7].chop.split(" ")
  # ---------------------------------------------
  $Type_Bloc = [type_PMB[0]+ " " + type_PMB[1],type_PMB[2],type_PMB[3],type_PMB[4]]
  $Style_Bloc = [style_PMB[0]+ " " + style_PMB[1],style_PMB[2],style_PMB[3],style_PMB[4]]
  $Longueur_Bloc = [longueur_PMB[0] + " " +longueur_PMB[1],longueur_PMB[2],longueur_PMB[3],longueur_PMB[4]]
  $Largeur_Bloc = [largeur_PMB[0]+" "+largeur_PMB[1],largeur_PMB[2],largeur_PMB[3],largeur_PMB[4]]
  $style_angle = [style_angle[0]+" "+style_angle[1],style_angle[2],style_angle[3]]
  $Hauteur = [hauteur_PMB[0]+" "+hauteur_PMB[1],hauteur_PMB[2],hauteur_PMB[3]]
  $long_linteau = [longueur_linteau_PMB[0]+" "+longueur_linteau_PMB[1],longueur_linteau_PMB[2],longueur_linteau_PMB[3]]
end

# -------------------------------------------
$Chargement_Fichier_Base_PMB  = true
