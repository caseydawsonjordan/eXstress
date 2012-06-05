<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="2.0">
	
	<xsl:param name="max_users"/>
	<xsl:param name="test_time"/>
	<xsl:param name="request_delay"/>
	<xsl:param name="interval"/>
	<xsl:param name="dump_traffic"/>
	
<xsl:output method="xml" indent="yes" omit-xml-declaration="yes" ></xsl:output>	
		
	<xsl:template match="tsung/@dumptraffic">
		<xsl:choose>
			<xsl:when test="$dump_traffic = 'true'">
				<xsl:attribute name="dumptraffic">
					<xsl:value-of select="'true'"/>
				</xsl:attribute>
				
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>	
		
	<xsl:template match="load/@duration|arrivalphase/@duration">
		<xsl:choose>
			<xsl:when test="$test_time">
				<xsl:attribute name="duration">
					<xsl:value-of select="$test_time"/>
				</xsl:attribute>
					
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy/>
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>	
	
	<xsl:template match="load/@unit|arrivalphase/@unit">
		<xsl:choose>
			<xsl:when test="$test_time">
				<xsl:attribute name="unit">
					<xsl:value-of select="'second'"/>
				</xsl:attribute>
				
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy/>
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>	
	
	<xsl:template match="users/@maxnumber">
		<xsl:choose>
			<xsl:when test="$max_users">
				<xsl:attribute name="maxnumber">
					<xsl:value-of select="$max_users"/>
				</xsl:attribute>
				
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy/>
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>	
	
	<xsl:template match="users/@interarrival">
		<xsl:choose>
			<xsl:when test="$interval">
				<xsl:attribute name="interarrival">
					<xsl:value-of select="$interval"/>
				</xsl:attribute>
				
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy/>
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>
	
	<xsl:template match="users/@unit">
		<xsl:choose>
			<xsl:when test="$interval">
				<xsl:attribute name="unit">
					<xsl:value-of select="'second'"/>
				</xsl:attribute>
				
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy/>
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>	
	
		
	<xsl:template match="request">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
		<xsl:if test="$request_delay > 0">
			<thinktime value="{$request_delay}" random="false"/>
		</xsl:if>
	</xsl:template>	
		
		
	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
	
</xsl:stylesheet>