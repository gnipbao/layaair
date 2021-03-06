package laya.d3.resource.models {
	import laya.d3.core.MeshSprite3D;
	import laya.d3.core.material.Material;
	import laya.d3.core.render.IRenderable;
	import laya.d3.core.render.RenderObject;
	import laya.d3.core.render.RenderQueue;
	import laya.d3.core.render.RenderState;
	import laya.d3.graphics.IndexBuffer3D;
	import laya.d3.graphics.VertexBuffer3D;
	import laya.d3.graphics.VertexDeclaration;
	import laya.d3.graphics.VertexElement;
	import laya.d3.graphics.VertexElementFormat;
	import laya.d3.graphics.VertexElementUsage;
	import laya.d3.math.Matrix4x4;
	import laya.d3.math.Vector3;
	import laya.d3.shader.ShaderDefines3D;
	import laya.d3.utils.Utils3D;
	import laya.utils.Stat;
	import laya.webgl.WebGLContext;
	import laya.webgl.shader.Shader;
	import laya.webgl.utils.Buffer;
	import laya.webgl.utils.Buffer2D;
	import laya.webgl.utils.ValusArray;
	
	/**
	 * @private
	 * <code>PrimitiveMesh</code> 类用于创建基本网格的父类。
	 */
	public class PrimitiveMesh extends BaseMesh implements IRenderable {
		protected var _numberVertices:int;
		protected var _numberIndices:int;
		protected var _vertexBuffer:VertexBuffer3D;
		protected var _indexBuffer:IndexBuffer3D;
		
		/** @private 烘焙后的顶点数据。*/
		private var _bakedVertexes:Float32Array;
		/** @private 烘焙后的索引数据。*/
		private var _bakedIndices:*;
		/** @private 是否烘焙*/
		private var _isVertexbaked:Boolean;
		/** @private */
		public var _indexOfHost:int;
		
		public function get indexOfHost():int {
			return _indexOfHost;
		}
		
		public function get VertexBufferCount():int {
			return 1;
		}
		
		public function get triangleCount():int {
			return _indexBuffer.indexCount / 3;
		}
		
		public function getVertexBuffer(index:int = 0):VertexBuffer3D {
			if (index === 0)
				return _vertexBuffer;
			else
				return null;
		}
		
		public function getIndexBuffer():IndexBuffer3D {
			return _indexBuffer;
		}
		
		/**
		 * 获取网格顶点
		 * @return 网格顶点。
		 */
		override public function get positions():Vector.<Vector3>//WEBGL1.0不能从Buffer显存中获取内存数据
		{
			var vertices:Vector.<Vector3> = new Vector.<Vector3>();
			
			var positionElement:VertexElement;
			var vertexElements:Array = _vertexBuffer.vertexDeclaration.getVertexElements();
			var j:int;
			for (j = 0; j < vertexElements.length; j++) {
				var vertexElement:VertexElement = vertexElements[j];
				if (vertexElement.elementFormat === VertexElementFormat.Vector3 && vertexElement.elementUsage === VertexElementUsage.POSITION0) {
					positionElement = vertexElement;
					break;
				}
			}
			
			var verticesData:Float32Array = _vertexBuffer.getData();
			for (j = 0; j < verticesData.length; j += _vertexBuffer.vertexDeclaration.vertexStride / 4) {
				var ofset:int = j + positionElement.offset / 4;
				var position:Vector3 = new Vector3(verticesData[ofset + 0], verticesData[ofset + 1], verticesData[ofset + 2]);
				vertices.push(position);
			}
			
			return vertices;
		}
		
		public function PrimitiveMesh() {
			super();
			_indexOfHost = 0;
		}
		
		/**
		 * @private
		 */
		private function _getShader(state:RenderState, vertexBuffer:VertexBuffer3D, material:Material):Shader {
			if (!material)
				return null;
			var def:int = 0;
			var shaderAttribute:* = vertexBuffer.vertexDeclaration.shaderAttribute;
			(shaderAttribute.UV) && (def |= material.shaderDef);
			(shaderAttribute.COLOR) && (def |= ShaderDefines3D.COLOR);
			(state.scene.enableFog) && (def |= ShaderDefines3D.FOG);
			def > 0 && state.shaderDefs.addInt(def);
			var shader:Shader = material.getShader(state);
			return shader;
		}
		
		/**
		 * @private
		 */
		protected function _addToRenderQuene(state:RenderState, material:Material):RenderObject {
			var o:RenderObject;
			if (!material.transparent || (material.transparent && material.transparentMode === 0))
				o = material.cullFace ? state.scene.getRenderObject(RenderQueue.OPAQUE) : state.scene.getRenderObject(RenderQueue.OPAQUE_DOUBLEFACE);
			else if (material.transparent && material.transparentMode === 1) {
				if (material.transparentAddtive)
					o = material.cullFace ? state.scene.getRenderObject(RenderQueue.DEPTHREAD_ALPHA_ADDTIVE_BLEND) : state.scene.getRenderObject(RenderQueue.DEPTHREAD_ALPHA_ADDTIVE_BLEND_DOUBLEFACE);
				else
					o = material.cullFace ? state.scene.getRenderObject(RenderQueue.DEPTHREAD_ALPHA_BLEND) : state.scene.getRenderObject(RenderQueue.DEPTHREAD_ALPHA_BLEND_DOUBLEFACE);
			}
			return o;
		}
		
		override public function getRenderElement(index:int):IRenderable {
			return this;
		}
		
		override public function getRenderElementsCount():int {
			return 1;
		}
		
		override protected function detoryResource():void {
			(_vertexBuffer) && (_vertexBuffer.dispose(), _vertexBuffer = null);
			(_indexBuffer) && (_indexBuffer.dispose(), _indexBuffer = null);
			memorySize = 0;
		}
		
		public function _render(state:RenderState):Boolean {
			_vertexBuffer._bind();
			_indexBuffer._bind();
			
			//TODO::临时放在此处,后期调整易移除......................
			var material:Material = state.renderObj.material;
			if (material) {
				var shader:Shader = _getShader(state, _vertexBuffer, material);
				
				var presz:int = state.shaderValue.length;
				state.shaderValue.pushArray(_vertexBuffer.vertexDeclaration.shaderValues);
				
				var meshSprite:MeshSprite3D = state.owner as MeshSprite3D;
				var worldMat:Matrix4x4 = meshSprite.transform.getWorldMatrix(-2);
				var worldTransformModifyID:Number = state.renderObj.tag.worldTransformModifyID;
				state.shaderValue.pushValue(Buffer2D.MATRIX1, worldMat.elements, worldTransformModifyID);
				Matrix4x4.multiply(state.projectionViewMatrix, worldMat, state.owner.wvpMatrix);
				state.shaderValue.pushValue(Buffer2D.MVPMATRIX, meshSprite.wvpMatrix.elements, state.camera.transform._worldTransformModifyID + worldTransformModifyID + state.camera._projectionMatrixModifyID);
				
				if (!material.upload(state, null, shader)) {
					state.shaderValue.length = presz;
					return false;
				}
				state.shaderValue.length = presz;
			}
			//TODO::临时放在此处,后期调整易移除....................
			
			state.context.drawElements(WebGLContext.TRIANGLES, _numberIndices, WebGLContext.UNSIGNED_SHORT, 0);
			Stat.drawCall++;
			Stat.trianglesFaces += _numberIndices / 3;
			return true;
		}
		
		public function getBakedVertexs(index:int, transform:Matrix4x4):Float32Array {
			if (index === 0) {
				if (_bakedVertexes)
					return _bakedVertexes;
				
				const byteSizeInFloat:int = 4;
				var vb:VertexBuffer3D = _vertexBuffer;
				_bakedVertexes = (vb.getData().slice() as Float32Array);//在红米2S微信中发现不支持slice();
				
				var vertexDeclaration:VertexDeclaration = vb.vertexDeclaration;
				var positionOffset:int = vertexDeclaration.shaderAttribute[VertexElementUsage.POSITION0][4] / byteSizeInFloat;
				var normalOffset:int = vertexDeclaration.shaderAttribute[VertexElementUsage.NORMAL0][4] / byteSizeInFloat;
				for (var i:int = 0; i < _bakedVertexes.length; i += vertexDeclaration.vertexStride / byteSizeInFloat) {
					var posOffset:int = i + positionOffset;
					var norOffset:int = i + normalOffset;
					
					Utils3D.transformVector3ArrayToVector3ArrayCoordinate(_bakedVertexes, posOffset, transform, _bakedVertexes, posOffset);
					Utils3D.transformVector3ArrayToVector3ArrayCoordinate(_bakedVertexes, normalOffset, transform, _bakedVertexes, normalOffset);
				}
				_isVertexbaked = true;
				return _bakedVertexes;
			} else
				return null;
		}
		
		public function getBakedIndices():* {
			if (_bakedIndices)
				return _bakedIndices;
			
			return _bakedIndices = _indexBuffer.getData();
		}
	
	}

}