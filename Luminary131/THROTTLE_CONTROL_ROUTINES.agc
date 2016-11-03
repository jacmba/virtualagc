### FILE="Main.annotation"
## Copyright:	Public domain.
## Filename:	THROTTLE_CONTROL_ROUTINES.agc
## Purpose:	A section of Luminary 1C, revision 131.
##		It is part of the source code for the Lunar Module's (LM)
##		Apollo Guidance Computer (AGC) for Apollo 13 and Apollo 14.
##		This file is intended to be a faithful transcription, except
##		that the code format has been changed to conform to the
##		requirements of the yaYUL assembler rather than the
##		original YUL assembler.
## Reference:	pp. 793-797 of 1729.pdf.
## Contact:	Ron Burkey <info@sandroid.org>.
## Website:	www.ibiblio.org/apollo/index.html
## Mod history:	05/24/03 RSB.	Began transcribing.
##		05/14/05 RSB	Corrected website reference above.

## Page 793
		BANK	31
		SETLOC	FTHROT
		BANK
		EBANK=	PIF
		COUNT*	$$/THROT

# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# HERE FC, DESIRED THRUST, AND FP, PRESENT THRUST, UNWEIGHTED, ARE COMPUTED.

THROTTLE	CA	ABDELV		# COMPUTE PRESENT ACCELERATION IN UNITS OF
		EXTEND			# 2(-4) M/CS/CS, SAVING SERVICER TROUBLE
		MP	/AF/CNST
 +3		EXTEND
 		QXCH	RTNHOLD
AFDUMP		TC	MASSMULT
		DXCH	FP		# FP = PRESENT THRUST
		EXTEND
		DCA	/AFC/
		TC	MASSMULT
		TS	FC		# FC = THRUST DESIRED BY GUIDANCE
		DXCH	FCODD		# FCODD = WHAT IT IS GOING TO GET

# COMPUTE DESIRED THRUST FOR DISPLAY AS A PERCENTAGE OF 10,500 POUNDS

		CAF	4FMAXNOM	# MOVE 4FMAXNOM TO ERASABLE FOR DV BELOW
		TS	Q
		CA	FC
		MASK	OCT17777	# FOR SAFETY
		EXTEND
		DV	Q
		EXTEND
		MP	4SECS
		TS	THRDISP		# FOR DISPLAY IN N92

# IF IT HAS BEEN LESS THAN 3 SECONDS SINCE THE LAST THROTTLING, AUGMENT FP USING THE FWEIGHT CALCULATED THEN.

		CS	TTHROT		# THIS CODING ASSUMES A FLATOUT WITHIN
		AD	TIME1		# 	80 SECONDS BEFORE FIRST THROTTLE CALL
		MASK	POSMAX
		COM
		AD	3SECS
		EXTEND
		BZMF	WHERETO		# BRANCH IF (TIME1-TTHROT +1) > 3 SECONDS
## Page 794
		EXTEND
		DCA	FWEIGHT
		DAS	FP

# THIS LOGIC DETERMINES THE THROTTLING IN THE REGION 10% - 94%.  THE MANUAL THROTTLE, NOMINALLY SET AT
# MINIMUM BY ASTRONAUT OR MISSION CONTROL PROGRAMS, PROVIDES THE LOWER BOUND.  A STOP IN THE THROTTLE HARDWARE
# PROVIDES THE UPPER.

WHERETO		CA	EBANK5		# INITIALIZE L*WCR*T AND H*GHCR*T FROM
		TS	EBANK		# 	PAD LOADED ERASABLES IN W-MATRIX
		EBANK=	LOWCRIT
		EXTEND
		DCA	LOWCRIT
		DXCH	L*WCR*T
		CA	EBANK7
		TS	EBANK
		EBANK=	PIF
		CS	ZERO		# INITIALIZE PIFPSET
		TS	PIFPSET
		CS	H*GHCR*T
		AD	FCOLD
		EXTEND
		BZMF	LOWFCOLD	# BRANCH IF FCOLD < OR = HIGHCRIT
		CS	L*WCR*T
		AD	FCODD
		EXTEND
		BZMF	FCOMPSET	# BRANCH IF FC < OR = LOWCRIT
		CA	FP		# SEE NOTE 1
		TCF	FLATOUT1

FCOMPSET	CS	FMAXODD		# SEE NOTE 2
		AD	FP
		TCF	FLATOUT2

LOWFCOLD	CS	H*GHCR*T
		AD	FCODD
		EXTEND
		BZMF	DOPIF		# BRANCH IF FC < OR = HIGHCRIT

		CA	FMAXPOS		# NO:  THROTTLE-UP
FLATOUT1	DXCH	FCODD
		CA	FEXTRA
FLATOUT2	TS	PIFPSET

# NOTE 1	FC IS SET EQUAL TO FP SO PIF WILL BE ZERO.  THIS IS DESIRABLE
#		AS THERE IS ACTUALLY NO THROTTLE CHANGE.
#
# NOTE2		HERE, SINCE WE ARE ABOUT TO RETURN TO THE THROTTLEABLE REGION
## Page 795
#		(BELOW 55%) THE QUANTITY -(FMAXODD-FP) IS COMPUTED AND PUT
#		INTO PIFPSET TO COMPENSATE FOR THE DIFFERENCE BETWEEN THE
#		NUMBER OF BITS CORRESPONDING TO FULL THROTTLE (FMAXODD) AND THE
#		NUMBER CORRESPONDING TO ACTUAL THRUST (FP).  THUS THE TOTAL
#		THROTTLE COMMAND PIF = FC - FP - (FMAXODD - FP) = FC - FMAXODD.

DOPIF		TC	FASTCHNG
		EXTEND
		DCA	FCODD
		TS	FCOLD
		DXCH	PIF
		EXTEND
		DCS	FP
		DAS	PIF		# PIF = FC - FP, NEVER EQUALS +0

DOIT		CA	PIF
		AD	PIFPSET		# ADD IN PIFPSET, WITHOUT CHANGING PIF
		TS	PSEUDO55
		TS	THRUST
		CAF	BIT4
		EXTEND
		WOR	CHAN14
		CA	TIME1
		TS	TTHROT

# SINCE /AF/ IS NOT AN INSTANTANEOUS ACELERATION, BUT RATHER AN "AVERAGE" OF THE ACCELERATION LEVELS DURING
# THE PRECEEDING PIPA INTERVAL, AND SINCE FP IS COMPUTED DIRECTLY FROM /AF/, FP IN ORDER TO CORRESPOND TO THE
# ACTUAL THRUST LEVEL AT THE END OF THE INTERVAL MUST BE WEIGHTED BY
# 	          PIF(PPROCESS + TL)     PIF /PIF/
#	FWEIGHT = ------------------ + -------------
#		       PGUID           2 PGUID FRATE
# WHERE PROCESS IS THE TIME BETWEEN PIPA READING AND THE START OF THROTTLING, PGUID IS THE GUIDANCE PERIOD, AND
# FRATE IS THE THROTTLING RATE (32 UNITS PER CENTISECOND).  PGUID IS EITHER 1 OR 2 SECONDS.  THE "TL" IN THE
# FIRST TERM REPRESENTS THE ENGINE'S RESPONSE LAG.  HERE FWEIGHT IS COMPUTED FOR USE NEXT PASS.

		CA	THISTPIP +1		# INITIALIZE FWEIGHT COMP AS IF FOR P66
		TS	BUF

		CS	MODREG			# ARE WE IN FACT IN P66?
		AD	DEC66
		EXTEND
		BZF	FWCOMP			# YES

		CA	PIPTIME +1		# NO:  INITIALIZE FOR TWO SECOND PERIOD
		TS	BUF
		CAF	4SECS
		TCF	FWCOMP +1
## Page 796

FWCOMP		CAF	2SECS
 +1		TS	Q
 		EXTEND
		MP	BIT6
		LXCH	BUF +1
		CS	BUF		# TIME OF LAST PIPA READIN.
		AD	TIME1
		AD	THROTLAG	# COMPENSATE FOR ENGINE RESPONSE LAG
		MASK	LOW8		# MAKE SURE SMALL AND POSITIVE
		ZL
		EXTEND
		DV	Q
		EXTEND
		MP	PIF
		DOUBLE
		DXCH	FWEIGHT
		CCS	PIF
		AD	ONE
		TCF	+2
		AD	ONE
		EXTEND
		MP	PIF
		EXTEND
		DV	BUF +1
		ZL
		DAS	FWEIGHT

THDUMP		TC	RTNHOLD

# FLATOUT THROTTLES UP THE DESCENT ENGINE, AND IS CALLED AS A BASIC SUBROUTINE.

FLATOUT		CAF	BIT13		# 4096 PULSES
WHATOUT		TS	PIFPSET		# USE PIFPSET SO FWEIGHT WILL BE ZERO
		CS	ZERO
		TS	FCOLD
		TS	PIF
		EXTEND
		QXCH	RTNHOLD
		TCF	DOIT

# MASSMULT SCALES ACCELERATION, ARRIVING IN A AND L IN UNITS OF 2(-4) M/CS/CS, TO FORCE IN PULSE UNITS.

MASSMULT	EXTEND
		QXCH	BUF
		DXCH	MPAC
		TC	DMP
		ADRES	MASS
## Page 797
		TC	DMP		# LEAVES PROPERLY SCALED FORCE IN MPAC
		ADRES	SCALEFAC
		TC	TPAGREE
		CA	MPAC
		EXTEND
		BZF	+3
		CAF	POSMAX
		TC	BUF
		DXCH	MPAC +1
		TC	BUF

# CONSTANTS --

FEXTRA		=	BIT13		# FEXT +5.13309020 E+4

/AF/CNST	DEC	.13107

OCT17777	OCT	17777
4FMAXNOM	DEC	14908		# EQUIVALENT TO 10,500 LBS.

# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
