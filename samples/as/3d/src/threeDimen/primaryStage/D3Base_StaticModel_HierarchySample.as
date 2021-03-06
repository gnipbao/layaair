package threeDimen.primaryStage {
	import laya.d3.component.animation.SkinAnimations;
	import laya.d3.core.Camera;
	import laya.d3.core.MeshSprite3D;
	import laya.d3.core.Sprite3D;
	import laya.d3.core.material.Material;
	import laya.d3.core.render.RenderState;
	import laya.d3.core.scene.Scene;
	import laya.d3.math.Vector3;
	import laya.d3.math.Viewport;
	import laya.d3.resource.models.BaseMesh;
	import laya.d3.resource.models.Mesh;
	import laya.display.Stage;
	import laya.events.Event;
	import laya.utils.Stat;
	
	public class D3Base_StaticModel_HierarchySample {
		private var skinMesh:MeshSprite3D;
		private var skinAni:SkinAnimations;
		
		public function D3Base_StaticModel_HierarchySample() {
			//是否抗锯齿
			//Config.isAntialias = true;
			Laya3D.init(0, 0);
			Laya.stage.scaleMode = Stage.SCALE_FULL;
			Laya.stage.screenMode = Stage.SCREEN_NONE;
			Stat.show();
			
			var scene:Scene = Laya.stage.addChild(new Scene()) as Scene;
			
			scene.currentCamera = (scene.addChild(new Camera( 0, 0.1, 100))) as Camera;
			scene.currentCamera.transform.translate(new Vector3(0, 0.8, 1.5));
			scene.currentCamera.transform.rotate(new Vector3(-30, 0, 0), true, false);
			
            //可采用预加载资源方式，避免异步加载资源问题，则无需注册事件。
			var staticMesh:Sprite3D = scene.addChild(new Sprite3D()) as Sprite3D;
			staticMesh.once(Event.HIERARCHY_LOADED, null, function(sprite:Sprite3D):void {
				var meshSprite:MeshSprite3D = sprite.getChildAt(0) as MeshSprite3D;
				var mesh:BaseMesh = meshSprite.mesh;
				mesh.once(Event.LOADED, null, function(mesh:BaseMesh):void {
					for (var i:int = 0; i < meshSprite.shadredMaterials.length; i++) {
						var material:Material = meshSprite.shadredMaterials[i];
						material.once(Event.LOADED, null, function(mat:Material):void{
								mat.luminance = 3.5;                              
						});
					}
				});
			});
			staticMesh.loadHierarchy("../../../../res/threeDimen/staticModel/simpleScene/B00IT001M000.v3f.lh");
			staticMesh.transform.localScale = new Vector3(10, 10, 10);
		}
	}
}