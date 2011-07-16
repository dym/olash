export BUILD_DIR=${PWD}/build/
export REGISTRY_DIR=~/.config/common-lisp/source-registry.conf.d/

get_hunchentoot:
	@echo "Downloading Hunchentoot"
	if [ -d "${BUILD_DIR}/hunchentoot" ] ; then \
	    cd ${BUILD_DIR}/hunchentoot && git pull; \
	else \
	    cd ${BUILD_DIR} && git clone https://github.com/archimag/hunchentoot.git; \
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
	    cd ${BUILD_DIR} && git clone https://github.com/dym/restas-odesk.git; \
	fi

bootstrap:
	mkdir -p ${BUILD_DIR}
	mkdir -p ${REGISTRY_DIR}
	$(MAKE) get_hunchentoot
	$(MAKE) get_restas
	$(MAKE) get_cl_odesk
	$(MAKE) get_restas_odesk
	echo "(:directory \"${BUILD_DIR}/hunchentoot/\")" > ${REGISTRY_DIR}/hunchentoot.conf
	echo "(:directory \"${BUILD_DIR}/restas/\")" > ${REGISTRY_DIR}/restas.conf
	#echo "(:directory \"${BUILD_DIR}/cl-odesk/\")" > ${REGISTRY_DIR}/cl-odesk.conf
	#echo "(:directory \"${BUILD_DIR}/restas-odesk/\")" > ${REGISTRY_DIR}/restas-odesk.conf
