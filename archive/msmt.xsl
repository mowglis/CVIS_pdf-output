<?xml version="1.0" encoding="iso-8859-2"?>
<xsl:stylesheet version="1.0"	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output indent="yes" method="html" encoding="iso-8859-2"/>

<xsl:template match="/">
	<html>
	<head>
		<title><xsl:value-of select="/data/nadpis"/></title>
		<style type="text/css">
			BODY {font-family:Verdana,sans-serif;}
			TD {font-family:Verdana,sans-serif;
					font-size:9pt;
			}
			TH {font-family:Verdana,sans-serif;
					font-size:9pt;
					font-weight:bold;
			}
		
		
		</style>
	</head>
	<body>
		<div align="left">
		<h1 align="center"><xsl:value-of select="/data/nadpis"/></h1>
		<xsl:apply-templates/>
		</div>
	</body>
	</html>
</xsl:template>

<xsl:template match="tabulka">
	<xsl:apply-templates select="nazev"/>
	<table border="1" cellspacing="0" cellpadding="3">
	<xsl:apply-templates select="radek"/>
	</table>
</xsl:template>

<xsl:template match="hodnota">
	<td><xsl:apply-templates/></td>
</xsl:template>

<xsl:template match="hodnota_num">
	<td align="right"><b><xsl:apply-templates/></b></td>
</xsl:template>

<xsl:template match="hodnota_err">
	<td bgcolor="red"><xsl:apply-templates/></td>
</xsl:template>

<xsl:template match="zahlavi">
	<th align="center"><xsl:apply-templates/></th>
</xsl:template>

<xsl:template match="radek">
	<tr>
		<xsl:apply-templates/>
	</tr>
</xsl:template>

<xsl:template match="nadpis">
</xsl:template>

<xsl:template match="nazev">
<h2><xsl:apply-templates/></h2>
</xsl:template>

<xsl:template match="datum">
<h3 align="center"><xsl:apply-templates/></h3>
</xsl:template>

<xsl:template match="data">
	<xsl:apply-templates/>
</xsl:template>

</xsl:stylesheet>
