################################################################################
# MEva.tcl - Mini-Eva (UWorld-like pour UnrealIRCD)
#
# Description:
#   Script TCL pour Eggdrop permettant la gestion de modération IRC via
#   des commandes simples. Fonctionne avec UnrealIRCD sans nécessiter de
#   connexion serveur directe, uniquement des droits IRCops.
#
# Auteurs: ZarTek-Creole & Tibs
# Version: 1.0.0
# Licence: Apache License 2.0
#
# Prérequis:
#   - Eggdrop configuré et fonctionnel
#   - UnrealIRCD avec droits IRCops pour le bot
#   - TCL 8.6
################################################################################

if { [info commands ::MEva::uninstall] eq "::MEva::uninstall" } { ::MEva::uninstall }


namespace eval MEva {
	variable SCRIPT
	variable CONF
	variable CMD_LIST

	array set SCRIPT {
		"name"				"MEva"
		"version"			"1.0.0"
		"auteur"			"ZarTek-Creole & Tibs"
	}

	array set CONF {
		"mode"				"M" 
		"prefix"			"m"
		"publicprefix"		"!"
		"raison_default"	"Merci de respecter la netiquette du réseau."
		"kick_prefix"		"Avertissement: "
		"ban_minutes"		60
		"action_signed"		1
		"signed_msg"		" - (par %s)"
	}
	
	set CMD_LIST 	[list \
						"help"		\
						"Op"		\
						"DeOp"		\
						"BotNick"	\
						"Voice"		\
						"DeVoice"	\
						"DeMode"	\
						"Kill"		\
						"Kick"		\
						"KB"		\
						"KickBan"	\
						"GLine"		\
	];
	   
    if { [string match -nocase *account-notify* [cap ls]] } { cap req account-notify; }

}
################################################################################
# Procédure de désinstallation
# Nettoie tous les bindings et supprime le namespace
################################################################################
proc ::MEva::uninstall {args} {
	variable SCRIPT
	putlog [format "Désallocation des ressources de \002%s\002..." ${SCRIPT(name)}];
	foreach binding [lsearch -inline -all -regexp [binds *[set ns [string range [namespace current] 2 end]]*] " \{?(::)?${ns}"] {
		unbind [lindex ${binding} 0] [lindex ${binding} 1] [lindex ${binding} 2] [lindex ${binding} 4];
	}
	namespace delete ::MEva
}

################################################################################
# Échappe les caractères spéciaux dans une chaîne pour utilisation sécurisée
# Paramètres: TEXT - texte à échapper
# Retourne: texte échappé
################################################################################
proc ::MEva::string_escape { TEXT } {
	return [string map {"\"" "\\\"" "\\" "\\\\" "\[" "\\\[" "\]" "\\\]" "\}" "\\\}" "\{" "\\\{"} ${TEXT}] 
}

################################################################################
# Crée les bindings pour une commande (public, privé, DCC)
# Paramètres: CMD_NAME - nom de la commande
################################################################################
proc ::MEva::proc_create { CMD_NAME } {
	variable CONF
	bind pub -|- ${CONF(publicprefix)}${CMD_NAME} "::MEva::proc_main ${CMD_NAME}"
	bind msg -|- ${CMD_NAME} "::MEva::proc_main ${CMD_NAME}"
	bind dcc -|- ${CMD_NAME} "::MEva::proc_main ${CMD_NAME}"
}

################################################################################
# Envoie un message selon le contexte (canal, privé, DCC)
# Paramètres: MSG - message à envoyer
################################################################################
proc ::MEva::msg MSG {
	variable SEND
	eval [subst [::MEva::string_escape ${SEND}]]; 
}

################################################################################
# Retourne la forme singulière ou plurielle selon la valeur
# Paramètres: value - valeur numérique
#            singular - forme singulière
#            plural - forme plurielle
# Retourne: forme appropriée
################################################################################
proc ::MEva::plural { value singular plural } {
	if { (${value} >= 2) || (${value} <= -2) } {
		return ${plural};
	} else {
		return ${singular};
	}
}
################################################################################
# Formate une durée en français (jours, heures, minutes, secondes)
# Paramètres: duration - durée en millisecondes
#            short - format court (1) ou long (0)
# Retourne: durée formatée en français
################################################################################
proc ::MEva::duration_fr {duration {short 0}} {
	set duration        [::tcl::string::trimleft ${duration} 0];
	set milliseconds    [::tcl::string::range ${duration} end-2 end];
	set duration        [::tcl::string::range ${duration} 0 end-3];
	if { ${duration} eq "" } { set duration 0; 	}
	set days            [expr {abs(${duration} / 86400)}];
	set hours           [expr {abs((${duration} % 86400) / 3600)}];
	set minutes         [expr {abs((${duration} % 3600) / 60)}];
	set seconds         [expr {${duration} % 60}];
	set valid_units     0;
	set counter         1;
	set output          {}
	foreach unit [list ${days} ${hours} ${minutes} ${seconds}] {
		if {
			(${unit} > 0)
			|| ((${counter} == 4)
			&& (${milliseconds} != 0))
		} then {
			switch -- ${counter} {
				1 {
					if { !${short} } {
						lappend output  "${unit} [::MEva::plural ${unit} "jour" "jours"]";
					} else {
						lappend output  "${unit}j";
					} 
				}
				2 {
					if { !${short} } {
						lappend output  "${unit} [::MEva::plural ${unit} "heure" "heures"]";
					} else {
						lappend output  "${unit}h";
					}
				}
				3 {
					if { !${short} } {
						lappend output  "${unit} [::MEva::plural ${unit} "minute" "minutes"]";
					} else {
						lappend output  "${unit}mn";
					}
				}
				4 {
					if { [::tcl::string::trimright ${milliseconds} 0] == "" } {
						set show_ms     0;
					} else {
						set show_ms     1;
					}
					set milliseconds    "[string repeat 0 [expr {3-[::tcl::string::length ${milliseconds}]}]]${milliseconds}";
					if { ${show_ms} } {
						if { !${short} } {
							lappend output  "${unit}.${milliseconds} [::MEva::plural "${unit}${milliseconds}" "seconde" "secondes"]";
						} else {
							lappend output  "${unit}.${milliseconds}s";
						}
					} else {
							if { !${short} } {
							lappend output  "${unit} [::MEva::plural ${unit} "seconde" "secondes"]";
						} else {
							lappend output  "${unit}s";
						}
					}
				}
			}
			incr valid_units
		}
		incr counter
	}
	if { !${short} } {
		if { ${valid_units} > 1 } {
			# Texte "et"
			set output [linsert ${output} end-1 "et"];
		}
		return [join ${output}];
	} else {
		return [join ${output} ""];
	}
}
################################################################################
# Procédure principale de traitement des commandes
# Détecte automatiquement le contexte (public, privé, DCC) et route vers
# la commande appropriée après vérification des permissions
# Paramètres: CMD_NAME - nom de la commande
#            args - arguments selon le contexte
################################################################################
proc ::MEva::proc_main { CMD_NAME args } {
	variable CONF
	variable SCRIPT
	variable SEND
	
	switch -- [llength ${args}] {
		5 {
			set bindprefix 		"${CONF(publicprefix)}${CONF(prefix)}"
			lassign ${args} 	nick host hand chan arg
			set SEND	"puthelp \"PRIVMSG ${chan} :\${MSG}\""
			set source_mode 	"public"
		}
		4 {
			set bindprefix		"${CONF(prefix)}"
			lassign ${args} 	nick host hand arg
			set SEND	"puthelp \"PRIVMSG ${nick} :\${MSG}\""
			set source_mode 	"private"
		}
		3 {
			set bindprefix		".${CONF(prefix)}"
			lassign ${args} 	nick idx arg
			set SEND	"putdcc ${idx} [list \${MSG}]"
			set source_mode 	"party"
		}
	}
	
	# Vérification des permissions Eggdrop
	if { ![matchattr [nick2hand ${nick}] ${CONF(mode)}] } {
		set MSG_ERROR 		[format "Vous ne disposez pas du drapeau Eggdrop '%s' nécessaire pour la commande %s." ${CONF(mode)} ${CMD_NAME}]
		::MEva::msg 		${MSG_ERROR}
		return -code error 	${MSG_ERROR}
	}
	switch -nocase ${CMD_NAME} \
		${CONF(prefix)}help		{
			::MEva::msg [format "\0030,3\002 Aide d'UWorld-NG (%s) version %s by %s." ${SCRIPT(name)} ${SCRIPT(version)} ${SCRIPT(auteur)}]
			::MEva::msg "\002${bindprefix}Op\002      <#salon> <pseudo>             \002->\002 Met le drapeau @operateur à <pseudo> sur le salon <#salon>."
			::MEva::msg "\002${bindprefix}DeOp\002    <#salon> <pseudo>             \002->\002 Retire le drapeau @operateur à <pseudo> sur le salon <#salon>."
			::MEva::msg "\002${bindprefix}Voice\002   <#salon> <pseudo>             \002->\002 Met le drapeau +voice sur le salon <#salon> à <pseudo>."
			::MEva::msg "\002${bindprefix}DeVoice\002 <#salon> <pseudo>             \002->\002 Retire le drapeau +voice sur le salon <#salon> à <pseudo>."
			::MEva::msg "\002${bindprefix}DeMode\002  <#salon> <pseudo>             \002->\002 Retire tous les drapeaux à <pseudo> sur le salon <#salon>."
			::MEva::msg "\002${bindprefix}Kick\002    <#salon> <pseudo> \[raison\]    \002->\002 Ejecter <pseudo> du salon <#salon> pour motif \[raison\]."
			::MEva::msg "\002${bindprefix}KB\002      <#salon> <pseudo> \[raison\]    \002->\002 Ejecter et bannir <pseudo> du salon <#salon> pour motif \[raison\]."
			::MEva::msg "\002${bindprefix}KickBan\002 <#salon> <pseudo> \[raison\]    \002->\002 Ejecter et bannir <pseudo> du salon <#salon> pour motif \[raison\]."
			::MEva::msg "\002${bindprefix}Kill\002    <pseudo> \[raison\]             \002->\002 Ejecter <pseudo> du serveur avec comme motif \[raison\]."
			::MEva::msg "\002${bindprefix}GLine\002   <pseudo> \[raison\]             \002->\002 Bannir globalement <pseudo> du réseau avec comme motif \[raison\]."
			::MEva::msg "\002${bindprefix}BotNick\002 <Nouveau Pseudo>              \002->\002 Changer le nom du robot en <Nouveau Pseudo>."
			return -code ok
		} \
		${CONF(prefix)}BotNick	{
			if { ${arg} == "" } {
				set MSG_ERROR 		[format "\002Usage:\002 %s <nick>" ${CMD_NAME}]
				::MEva::msg 		${MSG_ERROR}
				return -code error 	${MSG_ERROR}
			}
			set oldnick			 ${::nick}
			set ::nick 			[lindex ${arg} 0];
			set MSG				[format "\002Félicitation:\002 %s est maintenant %s." ${oldnick} ${::nick}]
			::MEva::msg 		${MSG}
			return -code ok 	${MSG}
		} \
		${CONF(prefix)}Op		{
			set channel	[lindex ${arg} 0]
			set who		[lindex ${arg} 1]
			if { ${channel} == "" || ${who} == "" } {
				set MSG_ERROR 		[format "\002Usage:\002 %s <#chan> <nick>" ${CMD_NAME}]
				::MEva::msg 		${MSG_ERROR}
				return -code error 	${MSG_ERROR}
			}
			putserv "MODE ${channel} +o ${who}"
			set MSG				[format "\002Félicitation:\002 %s est maintenant @opérateur sur %s." ${who} ${channel}]
			::MEva::msg 		${MSG}
			return -code ok 	${MSG}
		} \
		${CONF(prefix)}DeOp		{
			set channel	[lindex ${arg} 0]
			set who		[lindex ${arg} 1]
			if { ${channel} == "" || ${who} == "" } {
				set MSG_ERROR 		[format "\002Usage:\002 %s <#chan> <nick>" ${CMD_NAME}]
				::MEva::msg 		${MSG_ERROR}
				return -code error 	${MSG_ERROR}
			}
			putserv "MODE ${channel} -o ${who}"
			set MSG					[format "\002Félicitation:\002 %s n'est plus @opérateur sur %s." ${who} ${channel}]
			::MEva::msg 			${MSG}
			return -code ok 		${MSG}
		} \
		${CONF(prefix)}Voice	{
			set channel	[lindex ${arg} 0]
			set who		[lindex ${arg} 1]
			if { ${channel} == "" || ${who} == "" } {
				set MSG_ERROR 		[format "\002Usage:\002 %s <#chan> <nick>" ${CMD_NAME}]
				::MEva::msg 		${MSG_ERROR}
				return -code error 	${MSG_ERROR}
			}
			putserv "MODE ${channel} +v ${who}"
			set MSG					[format "\002Félicitation:\002 %s est maintenant +voice sur %s." ${who} ${channel}]
			::MEva::msg 			${MSG}
			return -code ok 		${MSG}
		} \
		${CONF(prefix)}DeVoice	{
			set channel	[lindex ${arg} 0]
			set who		[lindex ${arg} 1]
			if { ${channel} == "" || ${who} == "" } {
				set MSG_ERROR 		[format "\002Usage:\002 %s <#chan> <nick>" ${CMD_NAME}]
				::MEva::msg 		${MSG_ERROR}
				return -code error 	${MSG_ERROR}
			}
			putserv "MODE ${channel} -v ${who}"
			set MSG				[format "\002Félicitation:\002 %s n'est plus +voice sur %s." ${who} ${channel}]
			::MEva::msg 		${MSG}
			return -code ok 	${MSG}
		} \
		${CONF(prefix)}DeMode	{
			set channel	[lindex ${arg} 0]
			set who		[lindex ${arg} 1]
			if { ${channel} == "" || ${who} == "" } {
				set MSG_ERROR 		[format "\002Usage:\002 %s <#chan> <nick>" ${CMD_NAME}]
				::MEva::msg 		${MSG_ERROR}
				return -code error 	${MSG_ERROR}
			}
			putserv "MODE ${channel} -aqohv ${who} ${who} ${who} ${who} ${who}"
			set MSG				[format "\002Félicitation:\002 %s n'a plus aucun mode sur %s." ${who} ${channel}]
			::MEva::msg 		${MSG}
			return -code ok 	${MSG}
		} \
		${CONF(prefix)}Kill	{
			set who		[lindex ${arg} 0]
			set raison	[lrange ${arg} 1 end]
			if { ${who} == "" } {
				set MSG_ERROR 		[format "\002Usage:\002 %s <pseudo> \[raison\]" ${CMD_NAME}]
				::MEva::msg 		${MSG_ERROR}
				return -code error 	${MSG_ERROR}
			}
			if { ${raison} == "" } {
				set raison ${CONF(raison_default)};
			}
			if { ${CONF(action_signed)} } {
				append raison [format ${CONF(signed_msg)} ${nick}]
			}
			putserv "KILL ${who} :${raison}"
			set MSG				[format "\002Félicitation:\002 Vous avez éjécté '%s' du serveur pour le motif: '%s'" ${who} ${raison}]
			::MEva::msg 		${MSG}
			return -code ok 	${MSG}
		} \
		${CONF(prefix)}GLine	{
			set who		[lindex ${arg} 0]
			set raison	[lrange ${arg} 1 end]
			if { ${who} == "" } {
				set MSG_ERROR 		[format "\002Usage:\002 %s <pseudo> \[raison\]" ${CMD_NAME}]
				::MEva::msg 		${MSG_ERROR}
				return -code error 	${MSG_ERROR}
			}
			if { ${raison} == "" } {
				set raison ${CONF(raison_default)};
			}
			if { ${CONF(action_signed)} } {
				append raison [format ${CONF(signed_msg)} ${nick}]
			}
			set GLINE_MASK	"${who}!*@*"
			putserv "GLINE ${GLINE_MASK} :${raison}"
			set MSG				[format "\002Félicitation:\002 Vous avez banni globalement '%s' du réseau pour le motif: '%s'" ${who} ${raison}]
			::MEva::msg 		${MSG}
			return -code ok 	${MSG}
		} \
		${CONF(prefix)}Kick	{
			set channel		[lindex ${arg} 0]
			set who			[lindex ${arg} 1]
			set KICK_RAISON	[lrange ${arg} 2 end]
			if { ${channel} == "" || ${who} == "" } {
				set MSG_ERROR 		[format "\002Usage:\002 %s <#salon> <pseudo> \[raison\]" ${CMD_NAME}]
				::MEva::msg 		${MSG_ERROR}
				return -code error 	${MSG_ERROR}
			}
			if { ${KICK_RAISON} == "" } {
				set KICK_RAISON ${CONF(raison_default)};
			}
			if { ${CONF(action_signed)} } {
				append KICK_RAISON [format ${CONF(signed_msg)} ${nick}]
			}
			set KICK_RAISON			"${CONF(kick_prefix)}${KICK_RAISON}"
			putserv "KICK ${channel} ${who} :${KICK_RAISON}"
			set MSG				[format "\002Félicitation:\002 Vous avez éjécté '%s' du salon '%s' pour le motif: '%s'" ${who} ${channel} ${KICK_RAISON}]
			::MEva::msg 		${MSG}
			return -code ok 	${MSG}
		} \
		${CONF(prefix)}KB	- \
		${CONF(prefix)}KickBan	{
			
			set channel		[lindex ${arg} 0]
			set who			[lindex ${arg} 1]
			set KICK_RAISON	[lrange ${arg} 2 end]
			set BAN_MASK	"${who}!*@*"

			if { ${channel} == "" || ${who} == "" } {
				set MSG_ERROR 		[format "\002Usage:\002 %s <#salon> <pseudo> \[raison\]" ${CMD_NAME}]
				::MEva::msg 		${MSG_ERROR}
				return -code error 	${MSG_ERROR}
			}

			if { ${KICK_RAISON} == "" } {
				set KICK_RAISON ${CONF(raison_default)};
			}

			if { 
				${CONF(ban_minutes)} != "" 							&& \
				${CONF(ban_minutes)} >= 1
			} {
				utimer [expr ${CONF(ban_minutes)} * 60] [list putquick "MODE ${channel} -b ${BAN_MASK}"]
				append KICK_RAISON " (Expire le [strftime "%d/%m/%Y à %H:%M:%S" [clock add [clock seconds] ${CONF(ban_minutes)} minutes]] dans [::MEva::duration_fr [expr ${CONF(ban_minutes)}*60000]])"
			}

			if { ${CONF(action_signed)} } {
				append KICK_RAISON [format ${CONF(signed_msg)} ${nick}]
			}

			putquick "MODE ${channel} +b ${BAN_MASK}"
			putquick "KICK ${channel} ${who} :${KICK_RAISON}"

			set MSG				[format "\002Félicitation:\002 Vous avez éjecté '%s' du salon '%s' pour le motif: '%s'" ${who} ${channel} ${KICK_RAISON}]
			::MEva::msg 		${MSG}
			return -code ok 	${MSG}
		} \
		default 						{
			set MSG_ERROR		[format "Commande %s inconnue." ${CMD_NAME}]
			::MEva::msg 		${MSG_ERROR}
			return -code error 	${MSG_ERROR}
		}
}
################################################################################
# Gestion des événements JOIN avec extended-join (si disponible)
# Cette procédure est appelée lorsque extended-join est disponible
# Paramètres: from - origine du JOIN (nick!user@host)
#            kw - mot-clé (généralement vide pour JOIN)
#            text - paramètres additionnels (account, realname si extended-join)
#            flag - drapeaux additionnels
# Note: Actuellement non utilisée dans la logique métier, conservée pour compatibilité future
################################################################################
proc ::MEva::RAWJOIN {from kw text flag} {
	# Placeholder pour traitement futur des événements JOIN avec extended-join
}

################################################################################
# Gestion des événements JOIN sans extended-join (fallback)
# Cette procédure est appelée lorsque extended-join n'est pas disponible
# Paramètres: nick - pseudonyme de l'utilisateur
#            uhost - user@host
#            hand - handle Eggdrop (si enregistré)
#            chan - canal
# Note: Actuellement non utilisée dans la logique métier, conservée pour compatibilité future
################################################################################
proc ::MEva::BINDJOIN {nick uhost hand chan} {
	# Placeholder pour traitement futur des événements JOIN sans extended-join
}
################################################################################
# Initialisation du script
# Crée les bindings pour toutes les commandes et active les capacités IRC
################################################################################
proc ::MEva::init {} {
	variable CMD_LIST
	variable CONF
	variable SCRIPT
	
	# Créer les bindings pour toutes les commandes
	foreach CMD_NAME ${CMD_LIST} { 
		::MEva::proc_create ${CONF(prefix)}${CMD_NAME} 
	}
	
	# Activer account-notify si disponible
	if { 
		![string match *account-notify* [cap enabled]] 			&& \
		[string match -nocase *account-notify* [cap ls]]
	} {
		cap req account-notify
	}
	
	# Gérer extended-join si disponible
	if { [string match -nocase *extended-join* [cap ls]] } {
		if { ![string match *extended-join* [cap enabled]] } {
			cap req extended-join
		}
		bind RAWT - JOIN ::MEva::RAWJOIN
	} else {
		bind join - * ::MEva::BINDJOIN
	}

	putlog [format "Chargement de Mini-Eva (%s) version %s by %s" ${SCRIPT(name)} ${SCRIPT(version)} ${SCRIPT(auteur)}]
}
::MEva::init
