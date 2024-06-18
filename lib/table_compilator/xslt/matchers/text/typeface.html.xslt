<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:include href="../../templates/formatting.html.xslt" />
  <xsl:include href="../../templates/whitespace.html.xslt" />

  <xsl:template match="E[@T=02]">
    <xsl:call-template name="optional_preceding_whitespace" />
    <strong class="minor-caps">
      <xsl:apply-templates />
    </strong>
    <xsl:call-template name="optional_following_whitespace" />
  </xsl:template>

  <xsl:template match="E[@T=03]">
    <xsl:call-template name="optional_preceding_whitespace" />
    <em>
      <xsl:apply-templates />
    </em>
    <xsl:call-template name="optional_following_whitespace" />
  </xsl:template>

  <xsl:template match="E[@T=04]">
    <xsl:call-template name="optional_preceding_whitespace" />
    <strong>
      <xsl:apply-templates />
    </strong>
    <xsl:call-template name="optional_following_whitespace" />
  </xsl:template>

  <xsl:template match="E[@T=34]">
    <xsl:call-template name="optional_preceding_whitespace" />
    <span class="small-caps">
      <xsl:apply-templates />
    </span>
    <xsl:call-template name="optional_following_whitespace" />
  </xsl:template>

  <xsl:template match="E[@T=51]">
    <sup>
      <xsl:apply-templates />
    </sup>
    <xsl:call-template name="optional_following_whitespace" />
  </xsl:template>

  <xsl:template match="E[@T=0731]">
    <sup>
      <xsl:apply-templates />
    </sup>
    <xsl:call-template name="optional_following_whitespace" />
  </xsl:template>

  <xsl:template match="E[@T=7333]">
    <sup>
      <xsl:apply-templates />
    </sup>
    <xsl:call-template name="optional_following_whitespace" />
  </xsl:template>

  <xsl:template match="E[@T=7333]">
    <sup>
      <xsl:apply-templates />
    </sup>
    <xsl:call-template name="optional_following_whitespace" />
  </xsl:template>

  <xsl:template match="E[@T=52]">
    <sub>
      <xsl:apply-templates />
    </sub>
    <xsl:call-template name="optional_following_whitespace" />
  </xsl:template>

  <xsl:template match="E[@T=0732]">
    <sub>
      <xsl:apply-templates />
    </sub>
    <xsl:call-template name="optional_following_whitespace" />
  </xsl:template>

  <xsl:template match="E[@T=53]">
    <sup>
      <em>
        <xsl:apply-templates />
      </em>
    </sup>
    <xsl:call-template name="optional_following_whitespace" />
  </xsl:template>

  <xsl:template match="E[@T=54]">
    <xsl:call-template name="optional_preceding_whitespace" />
    <sub>
      <em>
        <xsl:apply-templates />
      </em>
    </sub>
    <xsl:call-template name="optional_following_whitespace" />
  </xsl:template>

  <!--  we've seen this when a footnote in a table gets messed up in the XML
        probably shoudln't be a normal occurance -->
  <xsl:template match="SU[not(ancestor::FTNT)]">
    <sup>
      <xsl:apply-templates />
    </sup>
    <xsl:call-template name="optional_following_whitespace" />
  </xsl:template>

  <!--
    text italicised in header
    See page 9 here: http://www.gpo.gov/fdsys/pkg/FR-2015-01-22/pdf/2015-00344.pdf
  -->
  <xsl:template match="E[@T=7462]">
    <!--<xsl:call-template name="optional_preceding_whitespace" />-->
    <em>
      <xsl:apply-templates />
    </em>
    <!--<xsl:call-template name="optional_following_whitespace" />-->
  </xsl:template>

  <xsl:template match="Q"/>
  
</xsl:stylesheet>
