<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:include href="./text/all.ecfr_bulkdata.html.xslt" />

  <xsl:template match="CHED/LI | ENT/LI">
    <xsl:text>

    </xsl:text>
    <xsl:if test="not(preceding-sibling::*[1][self::LI])">
      <xsl:text>
      ◜</xsl:text>
    </xsl:if>
    <br />
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="LI">
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="FR">
    <xsl:text>⏎</xsl:text>
    <fr>
      <xsl:apply-templates />
    </fr>
  </xsl:template>
</xsl:stylesheet>
