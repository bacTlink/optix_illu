
/*
* Copyright (c) 2008 - 2009 NVIDIA Corporation.  All rights reserved.
*
* NVIDIA Corporation and its licensors retain all intellectual property and proprietary
* rights in and to this software, related documentation and any modifications thereto.
* Any use, reproduction, disclosure or distribution of this software and related
* documentation without an express license agreement from NVIDIA Corporation is strictly
* prohibited.
*
* TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THIS SOFTWARE IS PROVIDED *AS IS*
* AND NVIDIA AND ITS SUPPLIERS DISCLAIM ALL WARRANTIES, EITHER EXPRESS OR IMPLIED,
* INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
* PARTICULAR PURPOSE.  IN NO EVENT SHALL NVIDIA OR ITS SUPPLIERS BE LIABLE FOR ANY
* SPECIAL, INCIDENTAL, INDIRECT, OR CONSEQUENTIAL DAMAGES WHATSOEVER (INCLUDING, WITHOUT
* LIMITATION, DAMAGES FOR LOSS OF BUSINESS PROFITS, BUSINESS INTERRUPTION, LOSS OF
* BUSINESS INFORMATION, OR ANY OTHER PECUNIARY LOSS) ARISING OUT OF THE USE OF OR
* INABILITY TO USE THIS SOFTWARE, EVEN IF NVIDIA HAS BEEN ADVISED OF THE POSSIBILITY OF
* SUCH DAMAGES
*/

#include <optix.h>
#include <optixu/optixu_math_namespace.h>
#include "ppm.h"
#include "helpers.h"
#include "random.h"

using namespace optix;

#define Total_Number 1

//
// Ray generation program
//

rtDeclareVariable(rtObject,      top_object, , );
rtBuffer<float4, 2>              output_buffer;
rtBuffer<float3, 2>              direct_buffer;
rtBuffer<float4, 2>              debug_buffer;

rtDeclareVariable(float, max_radius2, , );
rtBuffer<PackedPhotonRecord, 1>  photon_map;
rtBuffer<PackedHitRecord, 2>     rtpass_output_buffer;
rtBuffer<uint2, 2>               image_rnd_seeds;
rtDeclareVariable(float,         rtpass_default_radius2, , );
rtDeclareVariable(float,         scene_epsilon, , );
rtDeclareVariable(float,         alpha, , );
rtDeclareVariable(float,         total_emitted, , );
rtDeclareVariable(float, frame_number, , );
rtDeclareVariable(float, direct_ratio, , );
rtDeclareVariable(float, indirect_ratio, , );
rtDeclareVariable(float3,        ambient_light , , );
rtDeclareVariable(uint,          use_debug_buffer, , );
rtDeclareVariable(PPMLight,      light , , );
rtDeclareVariable(uint2, launch_index, rtLaunchIndex, );
rtDeclareVariable(ShadowPRD, shadow_prd, rtPayload, );

#define MAX_DEPTH 20 // one MILLION photons
#define MAX_KNN 1010

static __device__ inline float sqr(float a) { return a * a; }

RT_PROGRAM void initRadius()
{
	PackedHitRecord rec = rtpass_output_buffer[launch_index];
	float3 rec_position = make_float3( rec.a.x, rec.a.y, rec.a.z );
	
	unsigned int stack[MAX_DEPTH];
	unsigned int stack_current = 0;
	unsigned int node = 0; // 0 is the start

	double collection[MAX_KNN];
	double farestDis = 0;
	int farestId = 0;
	int currCollection = 0;
	int collectionNum = 10;

#define push_node(N) stack[stack_current++] = (N)
#define pop_node()   stack[--stack_current]

	push_node( 0 );

	int Photon_Map_size = photon_map.size(); // for debugging

	uint num_new_photons = 0u;
	size_t2 screen_size = output_buffer.size();
	uint loop_iter = 0;
	
	do {
		PackedPhotonRecord& photon = photon_map[ node ];

		uint axis = __float_as_int( photon.d.x );
		if( !( axis & PPM_NULL ) ) {

			float3 photon_position = make_float3( photon.a );
			float3 diff = rec_position - photon_position;
			float distance2 = dot(diff, diff);

			if (currCollection < collectionNum) {
				collection[currCollection] = distance2;
				farestDis = fmaxf(farestDis, distance2);
				farestId = currCollection;
				currCollection++;
			} else {
				if (farestDis > distance2) {
					collection[farestId] = distance2;
					farestDis = distance2;
					for (int i = 0; i < collectionNum; ++i) {
						if (collection[i] > farestDis) {
							farestDis = collection[i];
							farestId = i;
						}
					}
				}
			}

			// Recurse
			if( !( axis & PPM_LEAF ) ) {
				float d;
				if      ( axis & PPM_X ) d = diff.x;
				else if ( axis & PPM_Y ) d = diff.y;
				else                      d = diff.z;

				// Calculate the next child selector. 0 is left, 1 is right.
				int selector = d < 0.0f ? 0 : 1;
				if( currCollection < collectionNum || d*d <= farestDis ) {
					push_node( (node<<1) + 2 - selector );
				}
				node = (node<<1) + 1 + selector;
			} else {
				node = pop_node();
			}
		} else {
			node = pop_node();
		}
		loop_iter++;
	} while ( node );

	rec.c.z = farestDis;
	rtpass_output_buffer[launch_index] = rec;
}

RT_PROGRAM void init_any_hit()
{
	shadow_prd.attenuation = 0.0f;

	rtTerminateRay();
}

rtDeclareVariable(float3, rtpass_bad_color, , );
RT_PROGRAM void init_exception()
{
	output_buffer[launch_index] = make_float4(0.0f, 1.0f, 1.0f, 0.0f);
}