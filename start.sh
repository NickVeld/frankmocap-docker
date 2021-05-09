#!/bin/sh

python_site_packages_path=$(python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")

setup_package_in_develop_mode() {
  egg_link_filename="$1"
  egg_info_dirname="$2"
  package_dir="$3"
  setup_script_path="$4"

  egg_link_path="${python_site_packages_path}/${egg_link_filename}"

  if [ ! -f "${egg_link_path}" ] ; then
    if [ -d "${package_dir}/${egg_info_dirname}" ] ; then
      echo "$(pwd)/${package_dir}/" > ${egg_link_path}
      echo "$(pwd)/${package_dir}" >> ${python_site_packages_path}/easy-install.pth
    else
      if [ -f "${setup_script_path}" ] ; then
        sh ${setup_script_path}
      else
        echo "The setup routine is needed, but the setup script is not located. The expected path of the setup script"\
             "is \"${setup_script_path}\" relative to the current working directory \"$(pwd)\""
      fi
    fi
  fi
}

setup_package_in_develop_mode "faster-rcnn.egg-link" "faster_rcnn.egg-info" \
    "detectors/hand_object_detector/lib" "scripts/compile_hand_detectors.sh"

exec "$@"