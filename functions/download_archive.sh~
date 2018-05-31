# download_toolchain <url>
#
download_toolchain()
{
	local url=$1
	local filename=${url##*/}
	local dirname=${filename//.tar.xz}

	if [[ -f $SRC/cache/toolchains/$dirname/.download-complete ]]; then
		return
	fi

	cd $SRC/cache/toolchains/

	display_alert "Downloading" "$dirname"
	curl -Lf --progress-bar $url -o $filename
	curl -Lf --progress-bar ${url}.asc -o ${filename}.asc

	local verified=false

	display_alert "Verifying"
	if grep -q 'BEGIN PGP SIGNATURE' ${filename}.asc; then
		if [[ ! -d $SRC/cache/.gpg ]]; then
			mkdir -p $SRC/cache/.gpg
			chmod 700 $SRC/cache/.gpg
			touch $SRC/cache/.gpg/gpg.conf
			chmod 600 $SRC/cache/.gpg/gpg.conf
		fi
		(gpg --homedir $SRC/cache/.gpg --no-permission-warning --list-keys 8F427EAF || gpg --homedir $SRC/cache/.gpg --no-permission-warning --keyserver keyserver.ubuntu.com --recv-keys 8F427EAF) 2>&1 | tee -a $DEST/debug/output.log
		gpg --homedir $SRC/cache/.gpg --no-permission-warning --verify --trust-model always -q ${filename}.asc 2>&1 | tee -a $DEST/debug/output.log
		[[ ${PIPESTATUS[0]} -eq 0 ]] && verified=true
	else
		md5sum -c --status ${filename}.asc && verified=true
	fi
	if [[ $verified == true ]]; then
		display_alert "Extracting"
		tar --no-same-owner --overwrite -xf $filename && touch $SRC/cache/toolchains/$dirname/.download-complete
		display_alert "Download complete" "" "info"
	else
		display_alert "Verification failed" "" "wrn"
	fi
}

