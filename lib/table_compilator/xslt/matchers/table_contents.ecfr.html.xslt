<?xml version="1.0" encoding="ISO-8859-1" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:include href="./text/all.ecfr.html.xslt" />

  <xsl:template match="CHED/LI | ENT/LI">
    <xsl:text>

    </xsl:text>
    <xsl:if test="not(preceding-sibling::*[1][self::LI])">
      <xsl:text>
</xsl:text>
    </xsl:if>
    <br />
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="LI">
    <!-- add a space before and after -->
    <xsl:value-of select="' '" />
    <xsl:apply-templates />
    <xsl:value-of select="' '" />
  </xsl:template>

</xsl:stylesheet>
