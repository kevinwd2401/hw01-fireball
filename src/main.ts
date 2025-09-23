import {vec3} from 'gl-matrix';
import {vec4} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import Cube from './geometry/Cube';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';


let savedGui: dat.GUI;
// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 6,
  //'Load Scene': loadScene, // A function pointer, essentially
  mainColor: [200, 0, 0],
  secondaryColor: [220, 255, 40],
  sharpness: 3.2,
  colorSteps: 5.0,
  'Reset Fireball': resetValues
}
let icosphere: Icosphere;
// let square: Square;
// let cube: Cube;
let currTime: number = 0;
let prevTesselations: number = 7;

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  // square = new Square(vec3.fromValues(0, 0, 0));
  // square.create();
  // cube = new Cube(vec3.fromValues(0, 0, 0));
  // cube.create();
}

function resetValues() {
  
  controls.tesselations = 6;
  controls.mainColor = [200, 0, 0];
  controls.secondaryColor = [220, 255, 40];
  controls.sharpness = 3.2;
  controls.colorSteps = 5.0;
  savedGui.__controllers.forEach(c => c.updateDisplay());
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'tesselations', 0, 8).step(1);
  //gui.add(controls, 'Load Scene');
  gui.addColor(controls, 'mainColor');
  gui.addColor(controls, 'secondaryColor');
  gui.add(controls, 'sharpness', 2.0, 4.0).step(0.1);
  gui.add(controls, 'colorSteps', 3.0, 8.0).step(1.0);
  gui.add(controls, 'Reset Fireball');
  savedGui = gui;

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0., 0., 0.05, 1);
  gl.enable(gl.DEPTH_TEST);

  const custom = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/custom-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/custom-frag.glsl')),
  ]);

  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
    }
    currTime += 1;
    renderer.render(camera, custom, [
      //cube,
      icosphere,
      //square,
    ], vec4.fromValues(controls.mainColor[0] / 255.0, controls.mainColor[1]/ 255.0, controls.mainColor[2]/ 255.0, 1),
      vec4.fromValues(controls.secondaryColor[0] / 255.0, controls.secondaryColor[1]/ 255.0, controls.secondaryColor[2]/ 255.0, 1), 
      currTime, controls.sharpness, controls.colorSteps);
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
