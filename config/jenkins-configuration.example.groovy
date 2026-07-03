

// THIS IS ONLY AN EXAMPLE CONFIGURATION!!!


//!!! Important note: This file should be placed at /usr/share/hdm/jenkinsDateneinsatzConfig/
//!!! Important note: run ./BuilderJenkinsConfiguration.groovy to update configuration for Jenkins
//Release Auswahl (idealerweise 3 im Auswahl)
RELEASE=["20260614","20260801","20260401"]

//Default Einstellung fuer aktive Umgebungen
ENV_H_RELEASE="20260614"
ENV_I_RELEASE="20260614"
ENV_J_RELEASE="20260614"
ENV_K_RELEASE="20260401"
ENV_L_RELEASE="20260614"
ENV_M_RELEASE="20260401"
ENV_Q_RELEASE="20260614"


//Es werden bis zu 3 Release-abhaengige Filter Pattern unterstuetzt (DEFAULT, MAINTENANCE, ALTERNATIVE)
//ALTERNATIVE ist dafuer gedacht, nur im Ausnahmefälle zu benutzen, fuer mehr Pattern (als 3) ist besser das DEFAULT einfach mit * zu ersetzen
RELEASE_____DEFAULT="20260801"
RELEASE_MAINTENANCE="20260614"
RELEASE_ALTERNATIVE="20260401"

//Release-abhaegige Filter (als Prefixes)
TWE_____DEFAULT="_REL(0614|0801)"
TWE_MAINTENANCE="_REL(0614)"
TWE_ALTERNATIVE="_REL(0401|0614)"

LTBW_____DEFAULT="_R26(0614|0801)"
LTBW_MAINTENANCE="_R26(0614)"
LTBW_ALTERNATIVE="_R26(0401|0614)"

LTN_____DEFAULT="_R26(0614|0801)"
LTN_MAINTENANCE="_R26(0614)"
LTN_ALTERNATIVE="_R26(0401|0614)"

VERB_____DEFAULT="_R26(0614|0801)_V"
VERB_MAINTENANCE="_R26(0614)_V"
VERB_ALTERNATIVE="_R26(0401|0614)_V"

//Release-Unabhaengige Filter (als Prefixes)
bhf_DEFAULT="bhf-plan-202"
entry_DEFAULT="entry-pool-2"
poi_DEFAULT="poi-pool-2"
pakmap_DEFAULT="pakmap_2"
adr_DEFAULT="adressdaten-20"
//Stammdaten-Filter muss version heissen
//stammdaten_DEFAULT="FSTD_R2"
version_DEFAULT="FSTD_R2"

//Release-Unabhaengige Filter (regular Expr) - Fahrplandaten, Vorschau, Rückschau
connection_DEFAULT="0[0-9][0-9]_00[1-2]_BIBE_Plandaten_J26"

//connection_DEFAULT="[0-1][0-9][0-9]_00[1-2]_BIBE_Plandaten_J25"
connection_preview_DEFAULT="0[0-3][0-9]_00[1-3].*_Plandaten_J26"
connection_review_DEFAULT="[0-9][0-9][0-9]_00[1-2]_BIBE_Plandaten_J25"

//Vorschau / Rückschau Einstellung - separated list in one string with delimiter '|'
// the prefix 'x' is needed for easier regex logic
envs_preview="x"

//deaktivierte Umgebungen - separated list in one string with delimiter '|'
envs_deactivated="x|i|k|h|l|m"