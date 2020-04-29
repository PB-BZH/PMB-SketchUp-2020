# --------------------------------------------------
#       Nomenclature de la construction
# --------------------------------------------------
class GuiBase
  def initialize(mname)
    @modelName = mname
  end
  # titre de base utilisé pour toutes les pages html - pour indiquer la version de Construction PMB utilisé.
  @@title = "Nomenclature Construction PMB Version 1.1"
  # position relative de la page html
  @@cutlistui_location = 'UI_Nomenclature.html'
  # position relative du résultat 
  @@cutlistresult_location = 'Resultats_Nomenclature.html'
  def getVersionHtmlTitle
    return @@title
  end
  def getProjectLabelPrefix
    return " Pour le projet: "
  end
  def getUiHtmlLocation
    return @@cutlistui_location 
  end
  def getResultHtmlLocation
    return @@cutlistresult_location
  end
  def show(results)
    @results = results
    openDialog
    addCallbacks
    display
    return nil
  end ##ResultGui.displayResults
end

#-----------------------------------------------------------------------------
# class WebGui - for user to select the options and run the script from an html page 
# This dialog is what is displayed when the user first clicks on the plugin
# and is where we define the callback procedure for the html page to call to
# pass back and parse the selected parameters
#-----------------------------------------------------------------------------
class WebGui < GuiBase
  def openDialog
    @dlg = UI::WebDialog.new(getVersionHtmlTitle, true)
		path = Sketchup.find_support_file(getUiHtmlLocation ,"Plugins/MaisonPMB/HTML/")
    @dlg.set_file( path)
  end
  
  def addCallbacks
		@dlg.add_action_callback("get_data") do |web_dialog,action_name|
			if action_name=="pull_selection_count"
				total_selected = Sketchup.active_model.selection.length
				js_command = "passFromRubyToJavascript("+ total_selected.to_s + ")"
				web_dialog.execute_script(js_command)
			end
		end
    @dlg.add_action_callback("handleClose") {|d,p| @dlg.close()}
  end
  
  def display
    @dlg.show {}
  end
  
  def start
    @results=""
    show(@results)
    return nil
  end # start
  
end ## WebGui class
# -----------------------------
class Nomenclature
	Categorie = [
		"Standard",
		"Demi",
		"Compensation",
		"Angle_Droite",
		"Angle_Gauche",
		"Linteau",
		"Linteau fenetre",
		"Lisse basse",
		"Lisse basse fenetre",
		"bloc bord pignon gauche",
		"bloc bord pignon droite",
		"bloc haut pignon",
	]
	
	def initialize()
		#$dialog = WebGui.new("")
		#$dialog.start
		modele = Sketchup.active_model
		vue = modele.active_view
		@entites = modele.active_entities
		nomenclature = creation_fichier()
		if (nomenclature != false)
			table_mur = trier_table(reduit_table(Array.new(recherche_murs)))
			ecriture_fichier_nomenclature(table_mur, nomenclature)
			UI.messagebox("Traitement terminé")
		end
	end

	def recherche_murs
		liste_groupes = []
		liste_composants = []
		liste_pignon = []
		liste_fenetre = []
		liste_groupe = liste_composant = ""
		@entites.each do |groupe|
			if groupe.typename == "Group"
				entitie = groupe.entities
				entitie.each do |ent|
					if ent.typename == "Group"
						next if ent.name == ""
						nom = groupe.get_attribute('Info élément', 'nom')
						if ent.name == "pignon"
							liste_pignon += groupe.get_attribute('Info élément', 'liste_composant')
							next
						end
						if ent.name == "fenetre"
							liste_fenetre += ent.get_attribute('Info élément', 'liste_composant')
							#UI.messagebox(liste_fenetre)
							next
						end
						liste_groupe += (nom + ";" + ent.name+ "-")
						
					end
					if ent.typename == "ComponentInstance"
						next if ent.name == ""
						nom = groupe.get_attribute('Info élément', 'nom')
						liste_composant += (nom + ";" + ent.name + "-")
					end
					
				end
			end
		end
		liste_g = liste_groupe.split("-")
		i = 0
		liste_g.each {|str| liste_groupes[i]=str.split(";"); i+=1}
		#liste_groupes.each {|l| puts(l.inspect)}
		liste_c = liste_composant.split("-")
		#puts
		i = 0
		liste_c.each {|str| liste_composants[i]=str.split(";"); i+=1}
		#liste_composants.each {|l| puts(l.inspect)}
		table_mur = liste_groupes + liste_composants + liste_pignon + liste_fenetre
		liste_groupes = liste_composants = nil
		return table_mur
	end

	def recherche_mur
		base = 'mur'
		liste_mur = []
		0.upto(100) do |i|
			nom = base + i.to_s
			next if (PMB::Base_PMB.recherche_nom_entite(nom) == nil)
			liste_mur.push(nom)
		end
		#puts(liste_mur.inspect)
		return liste_mur
	end
	
	def reduit_table(table)
		return if(table == nil)
		table_temp = Array.new()
		#puts(table.length)
		while (table.length !=0)
			table.each do |item|
				next if (item == nil)
				tb = Array.new(item)
				compteur = 0
				i = table.index(tb)
				table.each do |t|
					next if (t == nil)
					k = table.index(t)
					compteur += 1 if (tb.inspect == t.inspect)
				end
				tb.push(compteur)
				table_temp.push(tb)
				table.delete(item)
			end
		end
		#table_temp.each {|t| puts(t.inspect)}
		return table_temp
	end

	def trier_table(table)
		return if(table == nil)
		table_temp = Array.new()
		copie_table = Array.new(table)
		liste_mur = recherche_mur()
		# tri par mur
		liste_mur.each do |nom|
			copie_table.each do |t|
				if (t[0] == nom)
					table_temp.push(t)
					table.delete(t)
				end
			end
		end
		table = Array.new(table_temp)
		table_temp = Array.new()
		# tri par catégorie
		i = 0
		liste_mur.each do |nom|
			mur = Array.new()
			copy_table = Array.new(table)
			copy_table.each  {|item| mur.push(item) if item[0] == nom}
			copy_table.each  {|item| table.delete(item) if item[0] == nom}
			copy_mur = Array.new(mur)
			Categorie.each do |cat|
				copy_mur.each do |cm|
					if(cm[3] == cat)
						mur.delete(cm)
						mur.push(cm)
					end
				end
			end
			table_temp.push(mur)
		end
		table = Array.new(table_temp)
		table_temp = copie_table = nil
		#table.each {|tb| tb.each {|t| puts(t.inspect)}}
		#UI.messagebox("Traitement terminé")
		return table
	end
	
	def creation_fichier
		chemin_fichier = Sketchup.active_model.path
		if chemin_fichier==""
			UI.messagebox("Ce document 'Sans titre' doit être sauvegarder avant cette opération !\nAbandon... ")
			return false
		end
		chemin_fichier = (chemin_fichier.split("\\")[0..-2]).join("/") #retire l'extension du nom de fichier courant
		nom_fichier = Sketchup.active_model.title
		nomenclature = chemin_fichier+"/"+nom_fichier+"_nomenclature.csv"
		begin
			fichier = File.new(nomenclature,"w")
		rescue               
			UI.messagebox("Fichier nomenclature:\n\n  "+nomenclature+"\n\nNe peut être sauvegarder\n\n1 - Vérifier que le fichier #{nom_fichier} est enregistré\n\n2 - Vérifier que le fichier #{nom_fichier+"_nomenclature.csv"} n'est pas déjà ouvert.\n\n3 - Fermer le fichier #{nom_fichier+"_nomenclature.csv"} et essayer à nouveau...\n\nAbandon...")
			return false
		end
		return fichier
	end
	
	def ecriture_fichier_nomenclature(table, fichier)
		table.each do |tb|
			fichier.puts(";#{tb[0][0]}")        
			tb.each do |item|
				fichier.puts(item[4].to_s+";"+item[3].to_s+";"+item[2].to_s+";"+item[1].to_s+";"+item[5].to_s)
			end
			fichier.puts
		end
		fichier.close()
	end
end

