if { [info commands ::MEva::uninstall] eq "::MEva::uninstall" } { ::MEva::uninstall }


namespace eval MEva {

	array set SCRIPT {
		"name"				"MEva"
		"version"			"0.0.1"
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
proc ::MEva::uninstall {args} {
	putlog [format "Désallocation des ressources de \002%s\002..." ${::MEva::SCRIPT(name)}];
	foreach binding [lsearch -inline -all -regexp [binds *[set ns [string range [namespace current] 2 end]]*] " \{?(::)?${ns}"] {
		unbind [lindex ${binding} 0] [lindex ${binding} 1] [lindex ${binding} 2] [lindex ${binding} 4];
	}
	namespace delete ::MEva
}
proc ::MEva::string_escape { TEXT } {
	return [string map {"\"" "\\\"" "\\" "\\\\" "\[" "\\\[" "\]" "\\\]" "\}" "\\\}" "\{" "\\\{"} ${TEXT}] 
}
proc ::MEva::proc_create { CMD_NAME } {
	bind pub -|- ${::MEva::CONF(publicprefix)}${CMD_NAME} "::MEva::proc_main ${CMD_NAME}"
	bind msg -|- ${CMD_NAME} "::MEva::proc_main ${CMD_NAME}"
	bind dcc -|- ${CMD_NAME} "::MEva::proc_main ${CMD_NAME}"
}
proc ::MEva::msg MSG { eval [subst [string_escape ${::MEva::SEND}]]; }
proc ::MEva::plural { value singular plural } {
	if { (${value} >= 2) || (${value} <= -2) } {
		return ${plural};
	} else {
		return ${singular};
	}
}
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
proc ::MEva::proc_main { CMD_NAME args } {
	switch -- [llength ${args}] {
		5 {
			set bindprefix 		"${::MEva::CONF(publicprefix)}${::MEva::CONF(prefix)}"
			lassign ${args} 	nick host hand chan arg
			set ::MEva::SEND	"puthelp \"PRIVMSG ${chan} :\${MSG}\""
			set source_mode 	"public"
		}
		4 {
			set bindprefix		"${::MEva::CONF(prefix)}"
			lassign ${args} 	nick host hand arg
			set ::MEva::SEND	"puthelp \"PRIVMSG ${nick} :\${MSG}\""
			set source_mode 	"private"
		}
		3 {
			set bindprefix		".${::MEva::CONF(prefix)}"
			lassign ${args} 	nick idx arg
			set ::MEva::SEND	"putdcc ${idx} [list \${MSG}]"
			set source_mode 	"party"
		}
	}
	if { ![matchattr [nick2hand ${nick}]  ${::MEva::CONF(mode)}] } {
		set MSG_ERROR 		[format "Vous ne disposez pas du drapeau Eggdrop '%s' nécessaire pour la commande %s." ${::MEva::CONF(mode)} ${CMD_NAME}]
		::MEva::msg 		${MSG_ERROR}
		return -code error 	${MSG_ERROR}
	}
	switch -nocase ${CMD_NAME} \
		${::MEva::CONF(prefix)}help		{
			::MEva::msg [format "\0030,3\002 Aide d'UWorld-NG (%s) version %s by %s." ${::MEva::SCRIPT(name)} ${::MEva::SCRIPT(version)} ${::MEva::SCRIPT(auteur)}]
			::MEva::msg "\002${bindprefix}Op\002      <#salon> <pseudo>             \002->\002 Met le drapeau @operateur à <pseudo> sur le salon <#salon>."
			::MEva::msg "\002${bindprefix}DeOp\002    <#salon> <pseudo>             \002->\002 Retire le drapeau @operateur à <pseudo> sur le salon <#salon>."
			::MEva::msg "\002${bindprefix}Voice\002   <#salon> <pseudo>             \002->\002 Met le drapeau +voice sur le salon <#salon> à <pseudo>."
			::MEva::msg "\002${bindprefix}DeVoice\002 <#salon> <pseudo>             \002->\002 Retire le drapeau +voice sur le salon <#salon> à <pseudo>."
			::MEva::msg "\002${bindprefix}DeMode\002  <#salon> <pseudo>             \002->\002 Retire tous les drapeaux à <pseudo> sur le salon <#salon>."
			::MEva::msg "\002${bindprefix}Kick\002    <#salon> <pseudo> \[raison\]    \002->\002 Ejecter <pseudo> du salon <#salon> pour motif \[raison\]."
			::MEva::msg "\002${bindprefix}Kill\002    <pseudo> \[raison\]             \002->\002 Ejecter <pseudo> du serveur avec comme motif \[raison\]."
			::MEva::msg "\002${bindprefix}GLine\002   <pseudo> \[raison\]             \002->\002 Ejecter <pseudo> du serveur avec comme motif \[raison\]."
			::MEva::msg "\002${bindprefix}BotNick\002 <Nouveau Pseudo>              \002->\002 Changer le nom du robot en <Nouveau Pseudo>."
			return -code ok
		} \
		${::MEva::CONF(prefix)}BotNick	{
			if { $arg == "" } {
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
		${::MEva::CONF(prefix)}Op		{
			set channel	[lindex ${arg} 0]
			set who		[lindex ${arg} 1]
			if { ${nick} == "" } {
				set MSG_ERROR 		[format "\002Usage:\002 %s <#chan> <nick>" ${CMD_NAME}]
				::MEva::msg 		${MSG_ERROR}
				return -code error 	${MSG_ERROR}
			}
			putserv "MODE ${channel} +o ${who}"
			set MSG				[format "\002Félicitation:\002 %s est maintenant @opérateur sur %s." ${nick} ${channel}]
			::MEva::msg 		${MSG}
			return -code ok 	${MSG}
		} \
		${::MEva::CONF(prefix)}DeOp		{
			set channel	[lindex ${arg} 0]
			set who		[lindex ${arg} 1]
			if { ${nick} == "" } {
				set MSG_ERROR 		[format "\002Usage:\002 %s <#chan> <nick>" ${CMD_NAME}]
				::MEva::msg 		${MSG_ERROR}
				return -code error 	${MSG_ERROR}
			}
			putserv "MODE ${channel} -o ${who}"
			set MSG					[format "\002Félicitation:\002 %s n'est plus @opérateur sur %s." ${who} ${channel}]
			::MEva::msg 			${MSG}
			return -code ok 		${MSG}
		} \
		${::MEva::CONF(prefix)}Voice	{
			set channel	[lindex ${arg} 0]
			set who		[lindex ${arg} 1]
			if { ${nick} == "" } {
				set MSG_ERROR 		[format "\002Usage:\002 %s <#chan> <nick>" ${CMD_NAME}]
				::MEva::msg 		${MSG_ERROR}
				return -code error 	${MSG_ERROR}
			}
			putserv "MODE ${chan} +v ${nick}"
			set MSG					[format "\002Félicitation:\002 %s est maintenant +voice sur %s." ${who} ${channel}]
			::MEva::msg 			${MSG}
			return -code ok 		${MSG}
		} \
		${::MEva::CONF(prefix)}DeVoice	{
			set channel	[lindex ${arg} 0]
			set who		[lindex ${arg} 1]
			if { ${nick} == "" } {
				set MSG_ERROR 		[format "\002Usage:\002 %s <#chan> <nick>" ${CMD_NAME}]
				::MEva::msg 		${MSG_ERROR}
				return -code error 	${MSG_ERROR}
			}
			putserv "MODE ${channel} -v ${who}"
			set MSG				[format "\002Félicitation:\002 %s n'est plus +voice sur %s." ${who} ${channel}]
			::MEva::msg 		${MSG}
			return -code ok 	${MSG}
		} \
		${::MEva::CONF(prefix)}DeMode	{
			set channel	[lindex ${arg} 0]
			set who		[lindex ${arg} 1]
			if { ${nick} == "" } {
				set MSG_ERROR 		[format "\002Usage:\002 %s <#chan> <nick>" ${CMD_NAME}]
				::MEva::msg 		${MSG_ERROR}
				return -code error 	${MSG_ERROR}
			}
			putserv "MODE ${channel} -aqohv ${who} ${who} ${who} ${who} ${who}"
			set MSG				[format "\002Félicitation:\002 %s n'a plus aucun mode sur %s." ${who} ${channel}]
			::MEva::msg 		${MSG}
			return -code ok 	${MSG}
		} \
		${::MEva::CONF(prefix)}Kill	{
			set who		[lindex ${arg} 0]
			set raison	[lrange ${arg} 1 end]
			if { ${nick} == "" } {
				set MSG_ERROR 		[format "\002Usage:\002 %s <pseudo> \[raison\]" ${CMD_NAME}]
				::MEva::msg 		${MSG_ERROR}
				return -code error 	${MSG_ERROR}
			}
			if { ${raison} == "" } {
				set raison ${::MEva::CONF(raison_default)};
			}
			if { ${::MEva::CONF(action_signed)} } {
				append raison [format ${::MEva::CONF(signed_msg)} ${nick}]
			}
			putserv "kill ${who} ${raison}"
			set MSG				[format "\002Félicitation:\002 Vous avez éjécté '%s' du serveur pour le motif: '%s'" ${nick} ${raison}]
			::MEva::msg 		${MSG}
			return -code ok 	${MSG}
		} \
		${::MEva::CONF(prefix)}kick	{
			set channel		[lindex ${arg} 0]
			set who			[lindex ${arg} 1]
			set KICK_RAISON	[lrange ${arg} 2 end]
			if { ${nick} == "" } {
				set MSG_ERROR 		[format "\002Usage:\002 %s <#salon> <pseudo> \[raison\]" ${CMD_NAME}]
				::MEva::msg 		${MSG_ERROR}
				return -code error 	${MSG_ERROR}
			}
			if { ${KICK_RAISON} == "" } {
				set KICK_RAISON ${::MEva::CONF(raison_default)};
			}
			if { ${::MEva::CONF(action_signed)} } {
				append KICK_RAISON [format ${::MEva::CONF(signed_msg)} ${nick}]
			}
			set KICK_RAISON			"${kick_prefix}${KICK_RAISON}"
			putserv "kick ${channel} ${who} ${KICK_RAISON}"
			set MSG				[format "\002Félicitation:\002 Vous avez éjécté '%s' du salon '%s' pour le motif: '%s'" ${who} ${channel} ${KICK_RAISON}]
			::MEva::msg 		${MSG}
			return -code ok 	${MSG}
		} \
		${::MEva::CONF(prefix)}kb	- \
		${::MEva::CONF(prefix)}kickban	{
			
			set channel		[lindex ${arg} 0]
			set who			[lindex ${arg} 1]
			set KICK_RAISON	[lrange ${arg} 2 end]
			set BAN_MASK	"${who}!*@*"

			if { ${nick} == "" } {
				set MSG_ERROR 		[format "\002Usage:\002 %s <#salon> <pseudo> \[raison\]" ${CMD_NAME}]
				::MEva::msg 		${MSG_ERROR}
				return -code error 	${MSG_ERROR}
			}

			if { ${KICK_RAISON} == "" } {
				set KICK_RAISON ${::MEva::CONF(raison_default)};
			}

			if { 
				${::MEva::CONF(ban_minutes)} != "" 							&& \
				${::MEva::CONF(ban_minutes)} >= 1
			} {
				utimer ${::MEva::CONF(ban_minutes)} [list putquick "MODE ${channel} -b ${BAN_MASK}"]
				append KICK_RAISON " (Expire le [strftime "%d/%m/%Y à %H:%M:%S" [clock add [clock seconds] ${::MEva::CONF(ban_minutes)} minutes]] dans [::MEva::duration_fr [expr ${::MEva::CONF(ban_minutes)}*60000]])"
			}

			if { ${::MEva::CONF(action_signed)} } {
				append KICK_RAISON [format ${::MEva::CONF(signed_msg)} ${nick}]
			}

			putquick "MODE ${channel} +b ${BAN_MASK}"
			putquick "kick ${channel} ${who} ${KICK_RAISON}"

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
# Use extended-join to perform the first test
    proc ::MEva::RAWJOIN {from kw text flag} {
		putlog "tessstt $from ** $kw ** $text ** $flag"
	}
proc ::MEva::init {} {
	foreach CMD_NAME ${::MEva::CMD_LIST} { ::MEva::proc_create ${::MEva::CONF(prefix)}${CMD_NAME} }
    if { 
		![string match *account-notify* [cap enabled]] 			&& \
		[string match -nocase *account-notify* [cap ls]]
	 } {
		 cap req account-notify
	}
	    if { [string match -nocase *extended-join* [cap ls]] } {
            if { ![string match *extended-join* [cap enabled]] } {
                cap req extended-join
            }
            bind RAWT - JOIN ::MEva::RAWJOIN
        } else {
            bind join - * ::MEva::BINDJOIN
        }

    putlog [format "Chargement de Mini-Eva (%s) version %s by %s" ${::MEva::SCRIPT(name)} ${::MEva::SCRIPT(version)} ${::MEva::SCRIPT(auteur)}]
}
::MEva::init
