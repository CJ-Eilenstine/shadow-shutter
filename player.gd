extends CharacterBody3D

@onready var pivot = $CamOrigin
@export var sens = 0.5
@export var CameraViewport: SubViewport # Reference to the Camera's SubViewport
@export var CameraPreview: TextureRect    # Reference to the TextureRect
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var pictureCount = 1
var pictureCapacity = 5

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	CameraPreview.texture = CameraViewport.get_texture()
	
	setupCamera()
	
func setupCamera():
	var dir = DirAccess.open("user://")
	dir.make_dir("pictures")
	
	dir = DirAccess.open("user://pictures")
	
	
	for n in dir.get_files():
		pictureCount += 1

func takePicture():
	if pictureCount != (pictureCapacity + 1):
		# Wait for the frame to be fully rendered
		await RenderingServer.frame_post_draw
		
		if CameraViewport and CameraViewport.get_texture():
			# Get the image from the camera's SubViewport instead of the default viewport
			var img = CameraViewport.get_texture().get_image()
			
			if img:
				img.save_png("user://pictures/picture"+str(pictureCount)+".png")
				pictureCount += 1
				
			else:
				print("Failed to capture the image from the SubViewport.")
		else:
			print("SubViewport or its texture is not available.")


func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * sens))
		pivot.rotate_x(deg_to_rad(-event.relative.y * sens))
		pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-90), deg_to_rad(45))
		
	if event.is_action_pressed("TakePicture"):
		takePicture()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_just_pressed("Quit"):
		get_tree().quit()
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("Left", "Right", "Forward", "Backword")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
