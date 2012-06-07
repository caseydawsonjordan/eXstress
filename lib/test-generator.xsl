<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="2.0">
	
	<xsl:param name="date-time"/>
	<xsl:variable name="tm" select="/test/modifiers"/>
	<xsl:variable name="tsung-plan" select="doc(resolve-uri(/test/plan/@src,document-uri(.) ))/tsung"/>
	<xsl:variable name="generated-test-src" select="resolve-uri(concat($date-time,'-gen-test.xml'), document-uri(root($tsung-plan)))"/>
	
	<xsl:output method="xml" indent="yes" name="xml" omit-xml-declaration="yes"/>
	<xsl:output method="text" indent="yes" omit-xml-declaration="yes" ></xsl:output>	
	
	<xsl:template match="/">
		<xsl:if test="not($tsung-plan)">
			<xsl:message terminate="yes">The test plan you specified is not valid.</xsl:message>
		</xsl:if>
		<xsl:result-document href="{$generated-test-src}" format="xml">
			<xsl:apply-templates select="$tsung-plan"></xsl:apply-templates>
		</xsl:result-document>
		<xsl:value-of select="string(replace($generated-test-src, 'file:', ''))"/>
	</xsl:template>
	
	<xsl:template match="tsung/@*">
		<xsl:variable name="att_name" select="local-name(.)"/>
		<xsl:variable name="att_ns" select="namespace-uri(.)"/>
		<xsl:variable name="overwrite-att" select="$tm/@*[local-name(.) = $att_name and namespace-uri(.) = $att_ns]"/>
		
		<xsl:choose>
			<xsl:when test="$overwrite-att">
				<xsl:copy-of select="$overwrite-att"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>	
	
	<xsl:template match="tsung/*">
		<xsl:variable name="node_name" select="local-name(.)"/>
		<xsl:variable name="node_ns" select="namespace-uri(.)"/>
		<xsl:variable name="overwrite" select="$tm/*[local-name(.) = $node_name and namespace-uri(.) = $node_ns]"/>
		<xsl:choose>
			<xsl:when test="$overwrite">
				<xsl:copy-of select="$overwrite"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy>
					<xsl:apply-templates select="@*|node()"/>
				</xsl:copy>
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>	
	
	<!--<xsl:template match="request">
		<xsl:copy>
		<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
		<xsl:if test="number($request_delay) > 0">
		<thinktime value="{$request_delay}" random="false"/>
		</xsl:if>
		</xsl:template>	-->
	
	
	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
	
</xsl:stylesheet>