<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:template match="FR | fr">
    <sup><xsl:value-of select="substring-before(., '/')"/></sup>
    <xsl:text>&#8260;</xsl:text>
    <sub><xsl:value-of select="substring-after(., '/')"/></sub>
  </xsl:template>
</xsl:stylesheet>
