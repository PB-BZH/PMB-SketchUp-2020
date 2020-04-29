require 'extensions.rb'
require 'LangHandler.rb'

$VERBOSE = nil
$DEBUG = nil
$DEBUG_ZONE_C = nil
$DEBUG_ZONE_E = nil
$DEBUG_ZONE_D = nil
$DEBUG_PIGNON = nil
$DEBUG_ZONE_C1 = nil
$DEBUG_ZONE_D1 = nil
$DEBUG_ZONE_B1 = nil
$DEBUG_ZONE_E1 = nil

$BarreOutils_MaisonPMB = nil
$MenuMaisonPMB=nil

GC.start()
ObjectSpace.garbage_collect()          

#Sketchup.active_model.start_operation("task",true)
$times0 = {'compt'=>0}
$times1 = {'compt'=>0}

# Affiche la console Ruby au démarage
Sketchup.send_action "showRubyPanel:" if $VERBOSE
#reponse = UI.messagebox("\tLICENCE\n\tVersion d'évaluation\n\n\tExpire le ",MB_YESNOCANCEL)

Sketchup.active_model.options["UnitsOptions"]["LengthSnapEnabled"]=true
Sketchup.active_model.options["UnitsOptions"]["LengthSnapLength"]=1.cm.to_l


# Extension Manager
$uStrings = LanguageHandler.new("Maison PMB")
MaisonPMB = SketchupExtension.new $uStrings.GetString("Maison PMB"), "MaisonPMB/sources/outilsMaisonPMB.rb"
MaisonPMB.description=$uStrings.GetString("Ensemble d'outils pour la construction en blocs de parpaing de bois massif : les blocs PMB")
MaisonPMB.name= "Maison PMB"
MaisonPMB.creator = "Patrick Bourges"
MaisonPMB.copyright = "PB_BZH Concept, 2011"
MaisonPMB.version = "1.2"

Sketchup.register_extension MaisonPMB, true
modele = Sketchup.active_model
#------------------------------------------------------------------------------------------
#                                    Elements du Menu PlugIn
#------------------------------------------------------------------------------------------
if not $MenuMaisonPMB
  # ajoute les éléments de menu pour lancer le plugin
  #--------------------------------------------------
  PMB_menu = UI.menu("Plugins")
  sous_menu1 = PMB_menu.add_submenu("Construction PMB")
sous_menu1.add_item("Options Globales")				{affiche_dialogue_options_globales()}
  #sous_menu.add_item("Bloc PMB")            {modele.select_tool PMB::OutilsBlocPMB.new()}

  sous_menu2 = sous_menu1.add_submenu("Murs et Pignon")
  sous_menu2.add_item("Création de murs")			{modele.select_tool PMB::Outils_Mur.new()}
  sous_menu2.add_item("Création de pignons")	{modele.select_tool PMB::Outils_Pignon.new()}
  sous_menu2.add_item("Edition Mur") {
    if(verifie_selection_mur)
      PMB::Edit_Outils_Mur.affiche_propriete_mur()
    else
      UI.messagebox "Aucune selection ou ce n'est pas un mur..."
    end
  }
  sous_menu2.add_item("Déplace le mur") {
    if(verifie_selection_mur)
      PMB::Edit_Outils_Mur.deplace_mur()
    else
      UI.messagebox "Aucune selection ou ce n'est pas un mur..."
    end
  }
  sous_menu2.add_item("Supprime le mur") {
    if(verifie_selection_mur)
     PMB::Edit_Outils_Mur.efface_mur()
    else
      UI.messagebox "Aucune selection ou ce n'est pas un mur..."
    end
  }

  sous_menu3 = sous_menu1.add_submenu("Fenêtres")
  sous_menu3.add_item("Ajouter une fenêtre") {
  	if mur = (verifie_selection_mur)
      modele.select_tool PMB::Outils_Fenetre.new(mur)
    else
      UI.messagebox "Aucune selection ou ce n'est pas un mur..."
    end
  }
  sous_menu3.add_item("Modifie les propriétés d'une fenêtre sur un mur") {
    if mur = (verifie_selection_mur)
      modele.select_tool PMB::Edit_Ouvertures_Mur.new(mur, "Fenetre", "MODIFIE")
    else
      UI.messagebox "Aucune selection ou ce n'est pas un mur..."
    end
  }
  sous_menu3.add_item(("Déplace une fenêtre sur un mur")) {
    if mur = (verifie_selection_mur)
      modele.select_tool PMB::Edit_Ouvertures_Mur.new(mur, "Fenetre", "DEPLACE")
    else
      UI.messagebox "Aucune selection ou ce n'est pas un mur..."
    end
  }
  sous_menu3.add_item("Efface une fenêtre sur un mur") {
    if mur = (verifie_selection_mur)
      modele.select_tool PMB::Edit_Ouvertures_Mur.new(mur, "Fenetre", "EFFACE")
    else
      UI.messagebox "Aucune selection ou ce n'est pas un mur..."
    end
  }

  sous_menu4 = sous_menu1.add_submenu("Portes")
  sous_menu4.add_item("Ajouter une porte") {
  	if mur = (verifie_selection_mur)
      modele.select_tool PMB::Outils_Porte.new(mur)
    else
      UI.messagebox "Aucune selection ou ce n'est pas un mur..."
    end
  }
  sous_menu4.add_item("Modifie les propriétés d'une porte du mur") {
    if mur = (verifie_selection_mur)
      modele.select_tool PMB::Edit_Ouvertures_Mur.new(mur, "Porte", "MODIFIE")
    else
      UI.messagebox "Aucune selection ou ce n'est pas un mur..."
    end
  }
  sous_menu4.add_item("Déplace une porte sur le mur") {
    if mur = (verifie_selection_mur)
      modele.select_tool PMB::Edit_Ouvertures_Mur.new(mur, "Porte", "DEPLACE")
    else 
      UI.messagebox "Aucune selection ou ce n'est pas un mur..."
    end 
  }
  sous_menu4.add_item("Efface une porte du mur") {
    if mur = (verifie_selection_mur)
      modele.select_tool PMB::Edit_Ouvertures_Mur.new(mur, "Porte", "EFFACE")
    else 
      UI.messagebox "Aucune selection ou ce n'est pas un mur..."
    end 
  }

#------------------------------------------------------------------------------------------
#                              Elements du Menu Contextuel
#------------------------------------------------------------------------------------------
  UI.add_context_menu_handler do |menu_contextuel|
    mur = PMB::Edit_Outils_Mur.recherche_selection_mur()
    if (mur)
      menu_contextuel.add_separator
      submenu = menu_contextuel.add_submenu("Edition des Murs") { PMB::Edit_Outils_Mur.editer_mur() }

      submenu1 = submenu.add_submenu("Murs et Pignons") 
      submenu1.add_item("Modifier les propriétés") { PMB::Edit_Outils_Mur.affiche_propriete_mur() }
      submenu1.add_item("Déplacer mur")            { PMB::Edit_Outils_Mur.deplace_mur() }
      submenu1.add_item("Effacer mur")             { PMB::Edit_Outils_Mur.efface_mur() }

      submenu2 = submenu.add_submenu("Fenêtres")
      submenu2.add_item("Ajouter fenêtre")         { modele.select_tool PMB::Outils_Fenetre.new(mur) }    
      submenu2.add_item("Modifier les propriétés") { modele.select_tool PMB::Edit_Ouvertures_Mur.new(mur, "Fenetre", "MODIFIE") }          
      submenu2.add_item("Déplacer fenêtre")        { modele.select_tool PMB::Edit_Ouvertures_Mur.new(mur, "Fenetre", "DEPLACE") }          
      submenu2.add_item("Effacer fenêtre")         { modele.select_tool PMB::Edit_Ouvertures_Mur.new(mur, "Fenetre", "EFFACE") }   

      submenu3 = submenu.add_submenu("Portes")
      submenu3.add_item("Ajouter porte")           { modele.select_tool PMB::Outils_Porte.new(mur)}          
      submenu3.add_item("Modifier les propriétés") { modele.select_tool PMB::Edit_Ouvertures_Mur.new(mur, "Porte", "MODIFIE") }          
      submenu3.add_item("Déplacer porte")          { modele.select_tool PMB::Edit_Ouvertures_Mur.new(mur, "Porte", "DEPLACE") }          
      submenu3.add_item("Effacer porte")           { modele.select_tool PMB::Edit_Ouvertures_Mur.new(mur, "Porte", "EFFACE") }          
    end
  end
  #----------------------------------------------------------------------------------------
  $MenuMaisonPMB=true
end 

#------------------------------------------------------------------------------------------
if( not $BarreOutils_MaisonPMB )

  #Barre d'outils PMB
  #----------------------------------------------------------------------------------------
  hb_tb = UI::Toolbar.new "Maison PMB"

  # Global settings
  cmd01 = UI::Command.new(("Global settings")) { affiche_dialogue_options_globales() }
  cmd01.small_icon = "MaisonPMB/icones/hb_globalsettings_S.png"
  cmd01.large_icon = "MaisonPMB/icones/hb_globalsettings_L.png"
  cmd01.tooltip = "Change les options globales"
  hb_tb.add_item(cmd01)
  hb_tb.add_separator
  # Floor tool
  #cmd01b = UI::Command.new(("Outils bloc PMB")) {modele.select_tool PMB::OutilsBlocPMB.new()}
  #cmd01b.small_icon = "MaisonPMB/icones/hb_floortool_S.png"
  #cmd01b.large_icon = "MaisonPMB/icones/hb_ComposerPMB_L.png"
  #cmd01b.tooltip = "Dessin de blocs PMB."
  #hb_tb.add_item(cmd01b)
  #hb_tb.add_separator
  
  # Floor tool
  #cmd02 = UI::Command.new(("Floor tool")) { Sketchup.active_model.select_tool PMB::FloorTool.new() }
  #cmd02.small_icon = "MaisonPMB/icones/hb_floortool_S.png"
  #cmd02.large_icon = "MaisonPMB/icones/hb_floortool_L.png"
  #cmd02.tooltip = "Création su sol."
  #hb_tb.add_item(cmd02)
  
  # Outils Mur
  cmd03 = UI::Command.new(("Outils Murs PMB")) { modele.select_tool PMB::Outils_Mur.new() }
  cmd03.small_icon = "MaisonPMB/icones/hb_walltool_S.png"
  cmd03.large_icon = "MaisonPMB/icones/hb_ajoute_mur_L.png"
  cmd03.tooltip = "Création d'un mur"
  hb_tb.add_item(cmd03)

  # Outils Pignon
  cmd03b = UI::Command.new(("Outils Pignons PMB")) { modele.select_tool PMB::Outils_Pignon.new() }
  cmd03b.small_icon = "MaisonPMB/icones/hb_gablewalltool_S.png"
  cmd03b.large_icon = "MaisonPMB/icones/hb_gablewalltool_L.png"
  cmd03b.tooltip = "Création d'un mur de pignon"
  hb_tb.add_item(cmd03b)

  # Change les propriétés du mur
  cmd04 = UI::Command.new(("Edition Mur")) {
    if(verifie_selection_mur)
      PMB::Edit_Outils_Mur.affiche_propriete_mur()
    else
      UI.messagebox "Aucune selection ou ce n'est pas un mur..."
    end
  }
  cmd04.small_icon = "MaisonPMB/icones/hb_changewallproperties_S.png"
  cmd04.large_icon = "MaisonPMB/icones/hb_changewallproperties_L.png"
  cmd04.tooltip = "Change les propriétés du mur"
  hb_tb.add_item(cmd04)
  
  # Déplace un mur
  cmd05 = UI::Command.new(("Déplace le mur")) {
    if(verifie_selection_mur)
      PMB::Edit_Outils_Mur.deplace_mur()
    else
      UI.messagebox "Aucune selection ou ce n'est pas un mur..."
    end
  }
  cmd05.small_icon = "MaisonPMB/icones/hb_movewall_S.png"
  cmd05.large_icon = "MaisonPMB/icones/hb_movewall_L.png"
  cmd05.tooltip = "déplace, pivote ou redimensionne le mur"
  hb_tb.add_item(cmd05)

  # Supprime un mur
  cmd06 = UI::Command.new(("Supprime le mur")) {
    if(verifie_selection_mur)
      PMB::Edit_Outils_Mur.efface_mur()
    else
      UI.messagebox "Aucune selection ou ce n'est pas un mur..."
    end
  }
  cmd06.small_icon = "MaisonPMB/icones/hb_supprime_mur_S.png"
  cmd06.large_icon = "MaisonPMB/icones/hb_supprime_mur_L.png"
  cmd06.tooltip = "Supprime le mur"
  hb_tb.add_item(cmd06)
  hb_tb.add_separator
  hb_tb.add_separator

  # Ajoute une fenêtre
  cmd08 = UI::Command.new(("Ajoute une fenêtre au mur")) {
    if mur = (verifie_selection_mur)
      modele.select_tool PMB::Outils_Fenetre.new(mur)
    else
      UI.messagebox "Aucune selection ou ce n'est pas un mur..."
    end
  }
  cmd08.small_icon = "MaisonPMB/icones/hb_addwindow_S.png"
  cmd08.large_icon = "MaisonPMB/icones/hb_ajoute_fenetre_L.png"
  cmd08.tooltip = "Ajoute une fenêtre au mur"
  hb_tb.add_item(cmd08)
  
  # Modifie les propriétés d'une fenêtre
  cmd09 = UI::Command.new(("Modifie les propriétés d'une fenêtre sur un mur")) {
    if mur = (verifie_selection_mur)
      modele.select_tool PMB::Edit_Ouvertures_Mur.new(mur, "Fenetre", "MODIFIE")
    else
      UI.messagebox "Aucune selection ou ce n'est pas un mur..."
    end
  }
  cmd09.small_icon = "MaisonPMB/icones/hb_changewindowproperties_S.png"
  cmd09.large_icon = "MaisonPMB/icones/hb_changewindowproperties_L.png"
  cmd09.tooltip = "Modifie les propriétés d'une fenêtre sur un mur"
  hb_tb.add_item(cmd09)
  
  # Déplace une fenêtre
  cmd10 = UI::Command.new(("Déplace une fenêtre sur un mur")) {
    if mur = (verifie_selection_mur)
      modele.select_tool PMB::Edit_Ouvertures_Mur.new(mur, "Fenetre", "DEPLACE")
    else
      UI.messagebox "Aucune selection ou ce n'est pas un mur..."
    end
  }
  cmd10.small_icon = "MaisonPMB/icones/hb_movewindow_S.png"
  cmd10.large_icon = "MaisonPMB/icones/hb_movewindow_L.png"
  cmd10.tooltip = "Déplace une fenêtre sur un mur"
  hb_tb.add_item(cmd10)
  
  # Efface une fenêtre
  cmd11 = UI::Command.new(("Efface une fenêtre sur un mur")) {
    if mur = (verifie_selection_mur)
      modele.select_tool PMB::Edit_Ouvertures_Mur.new(mur, "Fenetre", "EFFACE")
    else
      UI.messagebox "Aucune selection ou ce n'est pas un mur..."
    end
  }
  cmd11.small_icon = "MaisonPMB/icones/hb_deletewindow_S.png"
  cmd11.large_icon = "MaisonPMB/icones/hb_deletewindow_L.png"
  cmd11.tooltip = "Efface une fenêtre sur un mur"
  hb_tb.add_item(cmd11)
  hb_tb.add_separator
  hb_tb.add_separator
  
  # Add Porte
  cmd12 = UI::Command.new(("Ajoute une porte au mur")) {
    if mur = (verifie_selection_mur)
      modele.select_tool PMB::Outils_Porte.new(mur)
    else
      UI.messagebox "Aucune selection ou ce n'est pas un mur..."
    end
  }
  cmd12.small_icon = "MaisonPMB/icones/hb_addDoor_S.png"
  cmd12.large_icon = "MaisonPMB/icones/hb_addDoor_L.png"
  cmd12.tooltip = "Ajoute une porte au mur"
  hb_tb.add_item(cmd12)
  
  # Change Porte properties
  cmd13 = UI::Command.new(("Modifie les propriétés d'une porte du mur")) {
    if mur = (verifie_selection_mur)
      modele.select_tool PMB::Edit_Ouvertures_Mur.new(mur, "Porte", "MODIFIE")
    else
      UI.messagebox "Aucune selection ou ce n'est pas un mur..."
    end
  }
  cmd13.small_icon = "MaisonPMB/icones/hb_changedoorproperties_S.png"
  cmd13.large_icon = "MaisonPMB/icones/hb_changedoorproperties_L.png"
  cmd13.tooltip = "Modifie les propriétés d'une porte du mur"
  hb_tb.add_item(cmd13)
  
  # Move Porte
  cmd14 = UI::Command.new(("Déplace une porte sur le mur")) {
    if mur = (verifie_selection_mur)
      modele.select_tool PMB::Edit_Ouvertures_Mur.new(mur, "Porte", "DEPLACE")
    else 
      UI.messagebox "Aucune selection ou ce n'est pas un mur..."
    end 
  }
  cmd14.small_icon = "MaisonPMB/icones/hb_movedoor_S.png"
  cmd14.large_icon = "MaisonPMB/icones/hb_movedoor_L.png"
  cmd14.tooltip = "Déplace une porte sur le mur"
  hb_tb.add_item(cmd14)
  
  # Move Porte
  cmd15 = UI::Command.new(("Efface une porte du mur")) {
    if mur = (verifie_selection_mur)
      modele.select_tool PMB::Edit_Ouvertures_Mur.new(mur, "Porte", "EFFACE")
    else 
      UI.messagebox "Aucune selection ou ce n'est pas un mur..."
    end 
  }
  cmd15.small_icon = "MaisonPMB/icones/hb_deletedoor_S.png"
  cmd15.large_icon = "MaisonPMB/icones/hb_deletedoor_L.png"
  cmd15.tooltip = "Efface une porte du mur"
  hb_tb.add_item(cmd15)
  hb_tb.add_separator
  hb_tb.add_separator
  
  # Nomenclature
  cmd19 = UI::Command.new(("Nomenclature")) { Nomenclature.new() }
  cmd19.small_icon = "MaisonPMB/icones/hb_estimate_S.png"
  cmd19.large_icon = "MaisonPMB/icones/hb_estimate_L.png"
  cmd19.tooltip = "Nomenclature"
  hb_tb.add_item(cmd19)
  
  # Remerciements
  cmd20 = UI::Command.new(("A propos...")) {hb_Apropos()}
  cmd20.small_icon = "MaisonPMB/icones/hb_credits_S.png"
  cmd20.large_icon = "MaisonPMB/icones/hb_credits_L.png"
  cmd20.tooltip = "A propos"
  hb_tb.add_item(cmd20)
  
  
  # fin du chargement
  $BarreOutils_MaisonPMB = true

end
exec_on_autoload
#------------------------------------------------------------------------------------------
file_loaded("MaisonPMB.rb")
