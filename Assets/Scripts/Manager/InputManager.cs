using UnityEngine;

public class InputManager :MonoSingleton<InputManager>
{
    PlayerInput playerInput;

    protected override void InitSelf()
    {
        base.InitSelf();
        playerInput ??= new PlayerInput();
        playerInput.Enable();
    }
    public Vector2 rotInput;

    // Update is called once per frame
    void Update()
    {
        rotInput = playerInput.Game.RotInput.ReadValue<Vector2>();
    }
}
