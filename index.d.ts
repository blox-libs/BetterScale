interface Attributes {
	Range: NumberRange;
	Ratio: number;
	Resolution: Vector2;
	Axis: Enum.ScrollingDirection;
	DisplayRatio?: { [key: string]: number };
}

type GuiContainer = ScreenGui | DockWidgetPluginGui | BillboardGui | SurfaceGui;

interface BetterScaleInstance {
	GetAttributes(displaySize?: Enum.DisplaySize): Attributes;
	GetAbsoluteSize(): Vector2 | undefined;
	GetScale(): number | undefined;
	Update(): void;
	Track(): void;
	UnTrack(): void;
	Destroy(): void;
}

interface BetterScaleModule {
	new(uiScale: UIScale): BetterScaleInstance;
	build(uiScale: UIScale): () => void;
	is(value: unknown): value is BetterScaleInstance;
}

declare const BetterScale: BetterScaleModule;
export = BetterScale;
