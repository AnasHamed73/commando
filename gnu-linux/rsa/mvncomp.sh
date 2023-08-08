#!/bin/bash
# mvncomp: find the latest version(s) of a maven dependency artifact
# compatible with the specified java (major) release version.

###### CONSTANTS

DEFAULT_JAVA_RELEASE=8
DEFAULT_NUM_MATCHES=3
NUM_VERSIONS=200
WORK_DIR="$(mktemp -d -p /tmp)"
WGET_RES_PAGE="$WORK_DIR/search_res.json"

# this maps a java release to a specific class major version.
# Taken from the Wikipedia page:
# https://en.wikipedia.org/wiki/Java_version_history
declare -A R2V
R2V[1.0]=45
R2V[1.1]=45
R2V[1.2]=46
R2V[1.3]=47
R2V[1.4]=48
R2V[5]=49
R2V[6]=50
R2V[7]=51
R2V[8]=52
R2V[9]=53
R2V[10]=54
R2V[11]=55
R2V[12]=56
R2V[13]=57
R2V[14]=58
R2V[15]=59
R2V[16]=60
R2V[17]=61
R2V[18]=62
R2V[19]=63
R2V[20]=64
R2V[21]=65
ACC_RELS=$(echo ${!R2V[*]} | tr ' ' $'\n' | sort -Vr | sed ':a;N;$!ba;s/\n/, /g')

##### VARS

all=false
minimal=false
num_matches=

##### FUNCTIONS

usage() {
  echo "mvncomp: find the latest version(s) of a maven dependency artifact compatible with the specified java (major) release version."
  echo -e "\nUsage: mvncomp.sh [OPTIONS] <GROUP_ID> <ARTIFACT_ID>"
  echo -ne "\nOptions:"
  echo -e "\n-m|--minimal: produce minimal output"
  echo -e "-a|--all: process all the versions for the dependency (disabled by default)"
  echo -e "-n [NUM_MATCHES]|--num-matches [NUM_MATCHES]: process up to a specific number of matches (enabled by default; value is $DEFAULT_NUM_MATCHES)"
  echo -e "-j [RELEASE]|--java-release [RELEASE]: use a specific java release (default is $DEFAULT_JAVA_RELEASE)"
  echo -e "\t(note: acceptable releases are $ACC_RELS)"
  echo -e "\nExample: ./mvncomp.sh -a -j 11 some_group some_artifact"
  echo -e "the above example uses java release 11, and specifies the option to process all" \
    "versions for a dependency whose groupid is \"some_group\", and whose artifactId is \"some_artifact\""
}

debugln() {
  [ "$minimal" = false ] && echo -e "$1"
}

debug() {
  [ "$minimal" = false ] && echo -ne "$1"
}

clean_up_and_exit() {
  exit_code="$1"
  [ -e "$WORK_DIR" ] && rm -rf "$WORK_DIR"
  if [ -z "$1" ]; then
    exit_code=0
  fi
  exit "$exit_code"
}

###### MAIN

trap clean_up_and_exit SIGINT SIGTERM SIGHUP

while true; do
  case "$1" in
  "--help")
    usage
    exit 0
    ;;
  "-a" | "--all")
    if [ -n "$num_matches" ]; then
      echo "cannot specify both -a and -m options"
      clean_up_and_exit 1
    fi
    all=true
    shift
    ;;
  "-j" | "--java-release")
    shift
    java_rel=$1
    shift
    ;;
  "-n" | "--num-matches")
    if [ "$all" = true ]; then
      echo "cannot specify both -a and -m options"
      clean_up_and_exit 1
    fi
    shift
    num_matches=$1
    shift
    ;;
  "-m" | "--minimal")
    minimal=true
    shift
    ;;
  *)
    break
    ;;
  esac
done

if [ "$all" = false ] && [ -z "$num_matches" ]; then
  num_matches="$DEFAULT_NUM_MATCHES"
fi

gid="${1// /}"
aid="${2// /}"

if [ -z "$gid" ]; then
  echo "please provide groupId"
  clean_up_and_exit 1
fi
if [ -z "$aid" ]; then
  echo "please provide artifactId"
  clean_up_and_exit 1
fi
if [ -n "$java_rel" ] && [ -z "${R2V[$java_rel]}" ]; then
  echo "$java_rel is not a valid java release. A valid release is one of: $ACC_RELS"
  clean_up_and_exit 1
fi

gid_sep=${gid//\.//}

if [ -z "$java_rel" ]; then
  java_rel="$DEFAULT_JAVA_RELEASE"
fi
java_class_ver=${R2V["$java_rel"]}

debugln "\nOPTIONS:"
debugln "* groupId: $gid"
debugln "* artifactId: $aid"
debugln "* latest compatible java release: $java_rel -> class major version: $java_class_ver"
[ "$all" = true ] && debugln "* process all dependency versions: ${all:-false}\n"
[ -n "$num_matches" ] && debugln "* number of versions to match: ${num_matches:-false}\n"

mkdir -p "$WORK_DIR"

wget "https://search.maven.org/solrsearch/select?q=g:${gid}+AND+a:${aid}&core=gav&rows=${NUM_VERSIONS}&wt=json&sort=timestamp" \
  -O "$WGET_RES_PAGE" &>/dev/null \
  && debugln "fetched available versions"
vers=$(python -m json.tool "$WGET_RES_PAGE" \
  | grep "\"v\":" \
  | tr -d ' ' \
  | cut -d':' -f2 \
  | tr -d $'"' \
  | tr -d ',')
if [ -z "$vers" ]; then
  debugln "no artifacts found for ${gid}:${aid}"
  clean_up_and_exit
fi

debugln "checking versions"
num_matched=0
for ver in $vers; do
  jar_zip="$WORK_DIR/dep.jar"
  jar_unzip="$WORK_DIR/out"
  jar_url="https://search.maven.org/remotecontent?filepath=${gid_sep}/${aid}/${ver}/${aid}-${ver}.jar"
  wget "$jar_url" -O "$jar_zip" &>/dev/null || {
    debugln "failed to download jar for $ver"
    continue
  }
  debug "jar version: $ver -> "
  rm -rf "${jar_unzip:?}"/*
  unzip -o "$jar_zip" -d "$jar_unzip" &>/dev/null || {
    debugln "failed to unzip jar for $ver"
    continue
  }
  class_file=$(find "$jar_unzip" -mindepth 2 -name "*.class" ! -wholename "*/META-INF/*" | head -1)
  if [ -z "$class_file" ]; then
    debugln "no class files found"
    continue
  fi
  major_ver=$(javap -verbose "$class_file" | grep "major version" | cut -d':' -f2 | tr -d ' ')
  if [ -z "$major_ver" ]; then
    debugln "unable to determine class major version"
    continue
  fi
  debug "major version: $major_ver "
  if [ "$major_ver" -le "$java_class_ver" ]; then
    found=true
    if [ "$minimal" = false ]; then
      debugln "(java $java_rel compatible)"
    else
      echo "$ver"
    fi
    num_matched=$((num_matched + 1))
    if [ -n "$num_matches" ] && [ "$num_matched" -ge "$num_matches" ]; then
      break
    fi
  else
    debugln "(NOT java $java_rel compatible)"
  fi
done

if [ "$found" != true ]; then
  debugln "unable to find java $java_rel compatible version for $gid:$aid"
fi

clean_up_and_exit

