<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template name="fields">
    	<xsl:for-each select="defined_fields/Field">
		/types[<xsl:value-of select="../../@name"/>]/defined_fields[<xsl:value-of select="@name"/>]
    	</xsl:for-each>
      <xsl:if test="supers">
    	<xsl:for-each select="supers">
		<xsl:call-template name="fields"/>          
    	</xsl:for-each>
      </xsl:if>
</xsl:template>


<xsl:template match="/">
<!-- 
This XSLT file transforms a normal XML dump from schema.schema
to a bootstrap-compliant version by:
- Generating fields and add_fields from class.defined_fields
- Generating classes and primitives from schema.types
This is because bootstrap does not support computed fields
ie. inheritance and classes/primitives

TODO: Unable to traverse inheritance chain, fields==defined_fields
 -->
<Schema>
  <types>
    <xsl:for-each select="Schema/types">
      <xsl:copy-of select="Primitive"/>
    </xsl:for-each>
    <xsl:for-each select="Schema/types/Class">
    <Class>
	<xsl:attribute name="name">
		<xsl:value-of select="@name"/>
	</xsl:attribute><xsl:text>&#xa;</xsl:text>

      <xsl:if test="supers">
     <supers>
      <xsl:value-of select="supers"/>
     </supers><xsl:text>&#xa;</xsl:text>
      </xsl:if>

      <xsl:if test="subclasses">
     <subclasses>
      <xsl:value-of select="subclasses"/>
     </subclasses><xsl:text>&#xa;</xsl:text>
      </xsl:if>

      <xsl:if test="defined_fields">
	<defined_fields>
    <xsl:for-each select="defined_fields">
      <xsl:copy-of select="Field"/>
    </xsl:for-each>
	</defined_fields><xsl:text>&#xa;</xsl:text>
      </xsl:if>

      <xsl:if test="defined_fields">
	<fields>
		<xsl:call-template name="fields"/>
	</fields><xsl:text>&#xa;</xsl:text>
      </xsl:if>

      <xsl:if test="defined_fields">
	<all_fields>
		<xsl:call-template name="fields"/>
	</all_fields><xsl:text>&#xa;</xsl:text>
      </xsl:if>

    </Class><xsl:text>&#xa;</xsl:text>
    </xsl:for-each>
  </types>
  <classes>
    <xsl:for-each select="Schema/types/Class">
	/types[<xsl:value-of select="@name"/>]
    </xsl:for-each>
  </classes>
  <primitives>
    <xsl:for-each select="Schema/types/Primitive">
	/types[<xsl:value-of select="@name"/>]
    </xsl:for-each>
  </primitives>
</Schema>
</xsl:template>
</xsl:stylesheet>

