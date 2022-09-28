if { [info commands ::MEva::uninstall] eq "::MEva::uninstall" } { ::MEva::uninstall }
proc ::MEva::uninstall {args} {
	putlog "Désallocation des ressources de \002${::MEva::SCRIPT(name)}\002...";
	foreach binding [lsearch -inline -all -regexp [binds *[set ns [string range [namespace current] 2 end]]*] " \{?(::)?${ns}"] {
		unbind [lindex ${binding} 0] [lindex ${binding} 1] [lindex ${binding} 2] [lindex ${binding} 4];
	}
	namespace delete ::MEva
}

namespace eval MEva {
	array set SCRIPT {
		"name"		"MEva"
		"version"	"0.0.1"
		"auteur"	"ZarTek"
	}
}
proc ::MEva::aide {who idx arg} {
	putdcc ${idx} "\0030,3\002 Aide de Mini-Eva (${::MEva::SCRIPT(name)}) version ${::MEva::SCRIPT(version)} by ${::MEva::SCRIPT(auteur)} \002"
	putdcc ${idx} "\002aop \002 <#salon> <nick> -> Mettre le drapeau @oper à <nick> sur <#salon>"
	return 0
}
# .aop <#salon> <nick>
proc ::MEva::aop {who idx arg} {
	set chan	[lindex ${arg} 0]
	set nick	[lindex ${arg} 1]
	if { ${nick} == "" } {
		putdcc ${idx} "\002Usage:\002 .aop <#chan> <nick>\r"
		return 1
	}
	pushmode ${chan} +o ${nick}
	putdcc ${idx} [format "\002Félicitation:\002 %s est maintenant op sur %s." ${nick} ${chan}]

}
bind dcc n meva MEva::aide
bind dcc n aop MEva::aop
putlog "Chargement de Mini-Eva (${::MEva::SCRIPT(name)}) version ${::MEva::SCRIPT(version)} by ${::MEva::SCRIPT(auteur)}."