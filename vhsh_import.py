#!/usr/bin/env python3

# ///
# dependencies = [
#   "requests",
# ]
# [optional-dependencies]
# dotenv = ["python-dotenv"]
# ///

# TODO glslsandbox.com
# TODO dwitter.com

import sys
import os
import textwrap
from argparse import ArgumentError, ArgumentParser
from urllib.parse import urlparse
from enum import StrEnum
from pathlib import Path

import requests

class Source(StrEnum):
    SHADERTOY = "shadertoy"


def import_shadertoy(args):
    API_URL="https://www.shadertoy.com/api/v1/shaders/"
    VIEW_URL="https://www.shadertoy.com/view/"

    if not (api_key := os.getenv('VHSH_API_KEY_SHADERTOY')):
        raise RuntimeError("Set 'VHSH_API_KEY_SHADERTOY': https://www.shadertoy.com/myapps")

    if args.url.isalnum():
        id_ = args.url
    else:
        id_ = urlparse(args.url).path.split('/')[-1]

    url = f"// {VIEW_URL}{id_}"

    # TODO use session or auth provider?
    r = requests.get(API_URL + id_,
                     params={"key": api_key},
                     headers={"user-agent": "vhsh/0.1.0"})
    r.raise_for_status()
    shadertoy_info = r.json()

    info = shadertoy_info['Shader']['info']
    # header = textwrap.indent(json.dumps(info, indent=2), '// ')
    header = '\n'.join(f"// {k}: {v}" for k, v in info.items())
    src = next(
        filter(lambda rp: rp['name'] == 'Image',
               shadertoy_info['Shader']['renderpass'])
    )['code']

    """
    uniform vec3      iResolution;           // viewport resolution (in pixels)
    uniform float     iTime;                 // shader playback time (in seconds)
    uniform float     iTimeDelta;            // render time (in seconds)
    uniform float     iFrameRate;            // shader frame rate
    uniform int       iFrame;                // shader playback frame
    uniform float     iChannelTime[4];       // channel playback time (in seconds)
    uniform vec3      iChannelResolution[4]; // channel resolution (in pixels)
    uniform vec4      iMouse;                // mouse pixel coords. xy: current (if MLB down), zw: click
    uniform samplerXX iChannel0..3;          // input channel. XX = 2D/Cube
    uniform vec4      iDate;                 // (year, month, day, time in seconds)
    uniform float     iSampleRate;           // sound sample rate (i.e., 44100)
    """

    # TODO maybe arrays need to be defined as variables?
    # TODO maybe literals should be assigned to const variables?
    adapters = textwrap.dedent("""\
        #define iResolution vec3(u_Resolution, 0.0)
        #define iTime u_Time
        #define iTimeDelta 0.0
        #define iFrameRate 60.0
        #define iFrame (60.0 * u_Time)
        #define iChannelTime float[](u_Time, u_Time, u_Time, u_Time)
        #define iChannelResolution float[](vec3(u_Resolution, 0.0), vec3(u_Resolution, 0.0), vec3(u_Resolution, 0.0), vec3(u_Resolution, 0.0))
        #define iMouse vec4(0.0)
        // uniform samplerXX iChannel0..3; // input channel. XX = 2D/Cube
        #define iDate vec4(1970.0, 1.0, 1.0, 0.0)
        #define iSampleRate 44100.0
    """)

    main_func = textwrap.dedent("""\
        void main() {
            vec4 frag_color;
            mainImage(frag_color, gl_FragCoord.xy);
            FragColor = frag_color;
        }
    """)


    if not (filename := args.outfile):
        safe_name = ''.join(c for c in info['name'].replace(' ', '-')
                            if c.isalnum() or c in ['_', '-'])
        filename = f"{info['id']}_{safe_name}.glsl"

    with open(filename, 'w') as f:
        f.write('\n\n'.join([url, header, adapters, src, main_func]))
    print(f"wrote '{filename}'")


def main(argv=None):
    try:
        from dotenv import load_dotenv
        load_dotenv()
        print("loaded .env")
    except ImportError:
        pass


    parser = ArgumentParser()
    parser.add_argument("url")
    parser.add_argument("-o", "--outfile", type=Path)
    parser.add_argument("-t", "--type",type=Source, default=Source.SHADERTOY)
    args = parser.parse_args(argv)

    match args.type:
        case Source.SHADERTOY:
            import_shadertoy(args)
        case _:
            print(f"Source '{args.type}' not suported.", file=sys.stderr)
            exit(1)


if __name__ == '__main__':
    main()
