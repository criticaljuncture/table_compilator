<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:include href="../../templates/formatting.html.xslt" />
  <xsl:include href="../../templates/whitespace.html.xslt" />

  <xsl:strip-space elements="*"/>

  <xsl:template match="E">
    <xsl:element name="{local-name()}">
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="SU">
    <xsl:text>
    </xsl:text>
    <sup>
      <xsl:apply-templates />
    </sup>
    <!-- <xsl:if test="parent::*[self::CHED] and following-sibling::*[1][self::LI] and following-sibling::*[2][self::LI]">
      <xsl:text>
      </xsl:text>
    </xsl:if> -->
  </xsl:template>

  <xsl:template match="FR | fr">
    <xsl:text>
    </xsl:text>
    <xsl:element name="fr">
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>
</xsl:stylesheet>
