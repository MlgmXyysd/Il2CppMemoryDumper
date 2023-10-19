#!/system/bin/sh

echo "########################"
echo "# Il2Cpp Memory Dumper #"
echo "# by NekoYuzu neko.ink #"
echo "########################"

if [[ $1 == "" ]]; then
	echo "* Usage: $0 <package> [output]"
	exit
fi

package=$1

if [[ $2 == "" ]]; then
	out=/sdcard/dump
else
	out=$2
fi

echo "- Target package: $package"
echo "- Output directory: $out"

mkdir -p "$out"

user=$(am get-current-user)
pid=$(ps -ef | grep $package | grep u$user | awk '{print $2}')

if [[ $pid == "" ]]; then
	echo "! Target package of current user ($user) not found, is process running?"
	exit
fi

echo "- Found target process: $pid"

targets="global-metadata.dat libil2cpp.so "$(getprop ro.product.cpu.abilist | awk -F',' '{for (i = 1; i <= NF; i++) {gsub(/-/, "_"); print "split_config."$i".apk"}}')

for target in $targets; do
	local maps=$(grep $target /proc/$pid/maps | awk -v OFS='|' '{for (i = 1; i <= NF; i+=6) {print $i,$(i+1),$(i+2),$(i+3),$(i+4),$(i+5)}}')
	if [[ $maps != "" ]]; then
		if [[ $mem_list != "" ]]; then
			mem_list="${mem_list} ${maps}"
		else
			mem_list=$maps
		fi
	fi
done

cp /proc/$pid/maps "$out/${package}_maps.txt"

SYS_PAGESIZE=$(getconf PAGESIZE)
HEX_PAGESIZE=$(printf "%x" $SYS_PAGESIZE)

echo "- Starting dump process..."

lastFile=
lastEnd=
metadataOffset=

for memory in $mem_list; do
	local range=$(echo $memory | awk -F'|' '{print $1}')
	local offset=$(echo $range | awk -F'-' '{print toupper($1)}')
	local end=$(echo $range | awk -F'-' '{print toupper($2)}')
	local memIndicator=$(echo $memory | awk -v OFS=',' -F'|' '{print $4,$5}')
	local memName=$(echo $memory | awk -F'|' '{print $6}' | awk -F'/' '{print $NF}')
	
	local fileExt=
	
	if [[ $memName == "global-metadata.dat" ]]; then
		fileExt="dat"
	else
		dd if="/proc/$pid/mem" bs=1 skip=$(echo "ibase=16;$offset" | bc) count=4 of="${out}/tmp" 2>/dev/null
		
		if [[ $(cat "${out}/tmp") == $(echo -ne "\x7F\x45\x4C\x46") ]]; then
			fileExt="so"
			
			local EI_CLASS="None"
			dd if="/proc/$pid/mem" bs=1 skip=$(echo "ibase=16;${offset}+4" | bc) count=1 of="${out}/tmp" 2>/dev/null
			tmp=$(cat "${out}/tmp")
			if [[ $tmp == $(echo -ne "\x01") ]]; then
				EI_CLASS="32"
			elif [[ $tmp == $(echo -ne "\x02") ]]; then
				EI_CLASS="64"
			fi
			
			local EI_DATA="None"
			dd if="/proc/$pid/mem" bs=1 skip=$(echo "ibase=16;${offset}+5" | bc) count=1 of="${out}/tmp" 2>/dev/null
			tmp=$(cat "${out}/tmp")
			if [[ $tmp == $(echo -ne "\x01") ]]; then
				EI_DATA="LSB"
			elif [[ $tmp == $(echo -ne "\x02") ]]; then
				EI_DATA="MSB"
			fi
			
			local E_TYPE="None"
			dd if="/proc/$pid/mem" bs=1 skip=$(echo "ibase=16;${offset}+F" | bc) count=2 of="${out}/tmp" 2>/dev/null
			tmp=$(cat "${out}/tmp")
			if [[ $tmp == $(echo -ne "\x01\x00") ]]; then
				E_TYPE="Relocatable"
			elif [[ $tmp == $(echo -ne "\x02\x00") ]]; then
				E_TYPE="Executable"
			elif [[ $tmp == $(echo -ne "\x03\x00") ]]; then
				E_TYPE="Shared object"
			elif [[ $tmp == $(echo -ne "\x04\x00") ]]; then
				E_TYPE="Core"
			else
				E_TYPE="Processor-specific"
			fi
			
			echo "- ELF ${EI_CLASS}-Bit $E_TYPE (${EI_DATA} Encoding) was found at ${offset}, starting dump..."
		else
			fileExt="dump"
		fi
	fi
	
	local fileOut="${out}/${offset}_${package}_${memName}.${fileExt}"
	
	if [[ $memName == "global-metadata.dat" ]] || [[ $memName == "libil2cpp.so" && $fileExt == "so" ]]; then
		fileOut="${out}/${offset}_${package}_${memName}"
	fi
	
	if [[ $metadataOffset != "" ]] && [[ $(echo "ibase=16;(${metadataOffset}-${offset})<0" | bc) -ne 0 ]]; then
		echo "- Dumping [$memName] $range... <- This might be the correct libil2cpp.so"
		metadataOffset=
	else
		echo "- Dumping [$memName] $range..."
	fi
	
	dd if="/proc/$pid/mem" bs=$SYS_PAGESIZE skip=$(echo "ibase=16;${offset}/$HEX_PAGESIZE" | bc) count=$(echo "ibase=16;(${end}-${offset})/$HEX_PAGESIZE" | bc) of="$fileOut" 2>/dev/null
	
	if [[ $memName == "global-metadata.dat" ]]; then
		metadataOffset=$offset
		continue
	fi
	
	if [[ $? -ne 0 ]]; then
		echo "* Failed to dump memory $range, skipping..."
		continue
	fi
	
	memory=$(grep -i "${end}-" "/proc/$pid/maps" | grep "\[anon:.bss]")
	if [[ $memory != "" ]]; then
		range=$(echo $memory | awk '{print $1}')
		offset=$end
		end=$(echo $range | awk -F'-' '{print toupper($2)}')
		bss_block=$(echo "ibase=16;(${end}-${offset})/${HEX_PAGESIZE}" | bc)
		echo "- Adding [anonymous:.bss] $range..."
		dd if="/proc/$pid/mem" bs=$SYS_PAGESIZE skip=$(echo "ibase=16;${lastEnd}/$HEX_PAGESIZE" | bc) count=$bss_block of="$out/tmp" 2>/dev/null
		cat "$out/tmp">>"$fileOut"
	fi
	
	if [[ $fileExt == "so" ]]; then
		lastFile=$fileOut
	else
		if [[ $lastFile != "" ]]; then
			echo "- Merging memory..."
			skipMerge=false
			if [[ $lastEnd != $offset ]]; then
				local gap_block=$(echo "ibase=16;(${offset}-${lastEnd})/${HEX_PAGESIZE}" | bc)
				if [[ $gap_block -gt $SYS_PAGESIZE ]]; then
					echo "- Gap blocks $gap_block is too large, skipping merge..."
					skipMerge=true
					lastFile=$fileOut
					
					echo "- Patching last dump..."
					memory=$(grep -i "${lastEnd}-" "/proc/$pid/maps")
					offset=$(echo $memory | awk '{print $1}' | awk -F'-' '{print toupper($2)}')
					local patchIndicator=$(echo $memory | awk -v OFS=',' '{print $4,$5}')
					if [[ $patchIndicator != $memIndicator ]] && [[ $patchIndicator != "00:00,0" ]]; then
						echo "- Inconsistent memory files found, skipping patch..."
					else
						gap_block=$(echo "ibase=16;(${offset}-${lastEnd})/${HEX_PAGESIZE}" | bc)
						if [[ $gap_block -gt $SYS_PAGESIZE ]]; then
							echo "- Next region $gap_block is too large, skipping patch..."
						else
							echo "- Adding $gap_block blocks..."
							dd if="/proc/$pid/mem" bs=$SYS_PAGESIZE skip=$(echo "ibase=16;${lastEnd}/$HEX_PAGESIZE" | bc) count=$gap_block of="$out/tmp" 2>/dev/null
							cat "$out/tmp">>"$lastFile"
						fi
					fi
				else
					echo "- Adding $gap_block gap blocks..."
					dd if="/proc/$pid/mem" bs=$SYS_PAGESIZE skip=$(echo "ibase=16;${lastEnd}/$HEX_PAGESIZE" | bc) count=$gap_block of="$out/tmp" 2>/dev/null
					cat "$out/tmp">>"$lastFile"
				fi
			fi
			if [[ $skipMerge == "false" ]]; then
				cat "$fileOut">>"$lastFile"
				rm -f "$fileOut"
			fi
		else
			echo "- No ELF header found, but nothing to merge. Treating as a raw dump..."
			lastFile=$fileOut
		fi
	fi
	
	lastEnd=$end

	rm -f "${out}/tmp"
done

echo "- Done!"
