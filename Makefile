export BUILD_DIR=${PWD}/build/

get_hunchentoot:
	@echo "Downloading Hunchentoot"
	if [ -d "${BUILD_DIR}/hunchentoot" ] ; then \
	    cd ${BUILD_DIR}/hunchentoot && git pull; \
	else \
	    cd ${BUILD_DIR} && git clone https://github.com/edicl/hunchentoot.git;\
	fi

get_hunchentoot_cgi:
	@echo "Downloading Hunchentoot-CGI"
	if [ -d "${BUILD_DIR}/hunchentoot-cgi" ] ; then \
	    cd ${BUILD_DIR}/hunchentoot-cgi && git pull; \
	else \
	    cd ${BUILD_DIR} && git clone https://github.com/dym/hunchentoot-cgi.git; \
	fi

get_restas:
	@echo "Downloading RESTAS"
	if [ -d "${BUILD_DIR}/restas" ] ; then \
	    cd ${BUILD_DIR}/restas && git pull; \
	else \
	    cd ${BUILD_DIR} && git clone https://github.com/dym/restas.git; \
	fi

get_cl_odesk:
	@echo "Downloading cl-oDesk"
	if [ -d "${BUILD_DIR}/cl-odesk" ] ; then \
	    cd ${BUILD_DIR}/cl-odesk && git pull; \
	else \
	    cd ${BUILD_DIR} && git clone https://github.com/dym/cl-odesk.git; \
	fi

get_restas_odesk:
	@echo "Downloading RESTAS-oDesk"
	if [ -d "${BUILD_DIR}/restas-odesk" ] ; then \
	    cd ${BUILD_DIR}/restas-odesk && git pull; \
	else \
	    cd ${BUILD_DIR} && git clone https://github.com/dym/restas-odesk.git --branch cl-json; \
	fi

get_restas_dirpub:
	@echo "Downloading RESTAS-Directory-publisher"
	if [ -d "${BUILD_DIR}/restas-directory-publisher" ] ; then \
	    cd ${BUILD_DIR}/restas-directory-publisher && git pull; \
	else \
	    cd ${BUILD_DIR} && git clone https://github.com/archimag/restas-directory-publisher.git; \
	fi

get_cl_rbauth:
	@echo "Downloading cl-rbauth"
	if [ -d "${BUILD_DIR}/cl-rbauth" ] ; then \
	    cd ${BUILD_DIR}/cl-rbauth && git pull; \
	else \
	    cd ${BUILD_DIR} && git clone https://github.com/dym/cl-rbauth.git; \
	fi

bootstrap:
	mkdir -p ${BUILD_DIR}
	$(MAKE) get_hunchentoot
	$(MAKE) get_hunchentoot_cgi
	$(MAKE) get_restas
	$(MAKE) get_cl_odesk
	$(MAKE) get_restas_odesk
	$(MAKE) get_restas_dirpub
	$(MAKE) get_cl_rbauth

quickload:
	sbcl --noinform --script requirements.lisp