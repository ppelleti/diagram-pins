import Codec.Picture( PixelRGBA8( .. ), encodePngWithMetadata )
import Codec.Picture.Metadata as M
import Control.Monad
import qualified Data.ByteString.Lazy as L
import qualified Data.HashMap.Strict as H
import Data.Maybe
import Graphics.Rasterific
import Graphics.Rasterific.Texture
import Graphics.Rasterific.Transformations
import Graphics.Text.TrueType( Font, loadFontFile )
import System.IO.Unsafe

import Paths_diagram_pins

gpioToWpi :: H.HashMap Int Int
gpioToWpi = H.fromList $ zip (catMaybes wpiPins) [0..]

wpiPins :: [Maybe Int]
wpiPins =
  [ Just 17
  , Just 18
  , Just 27
  , Just 22
  , Just 23
  , Just 24
  , Just 25
  , Just 4
  , Just 2
  , Just 3
  , Just 8
  , Just 7
  , Just 10
  , Just 9
  , Just 11
  , Just 14
  , Just 15
  , Just 28
  , Just 29
  , Just 30
  , Just 31
  , Just 5
  , Just 6
  , Just 13
  , Just 19
  , Just 26
  , Just 12
  , Just 16
  , Just 20
  , Just 21
  , Just 0
  , Just 1
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  ]

physPins :: [Maybe Int]
physPins =
  [ Nothing
  , Nothing
  , Nothing
  , Just 2
  , Nothing
  , Just 3
  , Nothing
  , Just 4
  , Just 14
  , Nothing
  , Just 15
  , Just 17
  , Just 18
  , Just 27
  , Nothing
  , Just 22
  , Just 23
  , Nothing
  , Just 24
  , Just 10
  , Nothing
  , Just 9
  , Just 25
  , Just 11
  , Just 8
  , Nothing
  , Just 7
  , Just 0
  , Just 1
  , Just 5
  , Nothing
  , Just 6
  , Just 12
  , Just 13
  , Nothing
  , Just 19
  , Just 16
  , Just 26
  , Just 20
  , Nothing
  , Just 21
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Just 28
  , Just 29
  , Just 30
  , Just 31
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Nothing
  , Just 0
  ]

myFont :: Font
myFont = unsafePerformIO $ do
  vera <- getDataFileName "Vera.ttf"
  (Right f) <- loadFontFile vera
  return f

type Drwng = Drawing PixelRGBA8 ()

color r g b a = uniformTexture $ PixelRGBA8 r g b a

black = color 0 0 0 0xff
red = color 0xff 0 0 0xff
-- purple = color 0xff 0 0x40 0xff
gray = color 0x80 0x80 0x80 0xff

black' = PixelRGBA8 0 0 0 0xff
red' = PixelRGBA8 0xff 0 0 0xff
green' = PixelRGBA8 0 0xff 0 0xff
blue' = PixelRGBA8 0 0 0xff 0xff
white' = PixelRGBA8 0xff 0xff 0xff 0xff
purple' = PixelRGBA8 0x80 0 0xff 0xff
gray' = PixelRGBA8 0x80 0x80 0x80 0xff

blobLen = 70
halfBlob = blobLen / 2

rowHeight = 24
halfRow = rowHeight / 2

drawPin :: [(String, PixelRGBA8, PixelRGBA8)] -> Float -> Drwng
drawPin pairs mirror = withTexture black $ do
  fill $ circle (V2 0 0) 5
  let lineLen = 50 + (fromIntegral $ length pairs - 1) * (blobLen + 10)
  stroke 3 JoinRound (CapRound, CapRound) $ line (V2 0 0) (V2 lineLen 0)
  forM_ (zip pairs [0..]) $ \((str, c1, c2), i) -> do
    withTransformation (translate $ V2 (50 + i * (blobLen + 10)) 0) $ do
      withTexture (uniformTexture c1) $ fill $
        roundedRectangle (V2 (-halfBlob) (-10)) blobLen 20 10 10
      withTransformation (scale mirror 1) $ withTexture (uniformTexture c2) $
        printTextAt myFont (PointSize 12) (V2 (5 - halfBlob) 5) str

otherLabel :: Int -> String
otherLabel  1 = "3.3v"
otherLabel 17 = "3.3v"
otherLabel 50 = "3.3v"
otherLabel  2 = "5v"
otherLabel  4 = "5v"
otherLabel 49 = "5v"
otherLabel  _ = "Ground"

otherFunc :: Int -> [(String, PixelRGBA8, PixelRGBA8)]
{-
I'm puzzled... the wiringPi source code says that only
BCM_GPIO_4 and BCM_GPIO_21 are usable as GP Clock, but
doesn't explain why.  On the other hand, pinout.xyz shows
BCM_GPIO_4, BCM_GPIO_5, and BCM_GPIO_6 as supporting
GP Clock, but it doesn't mention BCM_GPIO_21.

https://github.com/WiringPi/WiringPi/blob/e687f3f2c62079c48c89cbca5a5ebe8ec259d1c0/wiringPi/wiringPi.c#L575

https://pinout.xyz/pinout/gpclk
-}
otherFunc  7 = [("Clock", purple', white')] -- BCM_GPIO_4
otherFunc 29 = [("Clock", purple', white')] -- BCM_GPIO_5
otherFunc 31 = [("Clock", purple', white')] -- BCM_GPIO_6
otherFunc 40 = [("Clock", purple', white')] -- BCM_GPIO_21
otherFunc 32 = [("PWM", purple', white')]
otherFunc 33 = [("PWM", purple', white')]
otherFunc 12 = [("PWM", purple', white')]
otherFunc 35 = [("PWM", purple', white')]
otherFunc _ = []

getPinInfo :: Int -> [(String, PixelRGBA8, PixelRGBA8)]
getPinInfo pin =
  let gpio = physPins !! pin
      wpi = case gpio of
              Nothing -> Nothing
              (Just x) -> H.lookup x gpioToWpi
  in case (gpio, wpi) of
       (Just gpio', Just wpi') -> [ ("Phys" ++ show pin, black', white')
                                  , ("Gpio" ++ show gpio', green', black')
                                  , ("Wpi"  ++ show wpi', blue', white')
                                  ] ++ otherFunc pin
       _ -> [ (otherLabel pin, gray', white') ]

handlePin :: Int -> Drwng
handlePin pin = do
  let pin' = pin - 1
      (row, side) = pin' `divMod` 2
      mirror = side * 2 - 1
      row' = fromIntegral row
      mirror' = fromIntegral mirror
      pinInfo = getPinInfo pin
  withTransformation (scale mirror' 1) $
    withTransformation (translate $ V2 10 (row' * rowHeight)) $
    drawPin pinInfo mirror'

drawing :: Drwng
drawing = do
  let lineX = 4 * (blobLen + 10) + 15
      lineY = 13 * rowHeight - halfRow
  withTexture red $ do
    printTextAt myFont (PointSize 18) (V2 (-16) (21 * rowHeight - 10)) "P1"
    printTextAt myFont (PointSize 18) (V2 (-16) (23 * rowHeight + 5)) "P5"
    printTextAt myFont (PointSize 8) (V2 (-lineX) (lineY - 5)) "Model A/B"
    printTextAt myFont (PointSize 8) (V2 (-lineX) (lineY + 13)) "Model A+/B+"
  withTexture gray $ do
    fill $ rectangle (V2 (-20) (-halfRow)) 40 (20 * rowHeight)
    fill $ rectangle (V2 (-20) (24 * rowHeight - halfRow)) 40 (4 * rowHeight)
  withTexture red $
    dashedStroke [10, 10] 2 (JoinMiter 0) (CapStraight 0, CapStraight 0) $
    line (V2 (-lineX) lineY) (V2 lineX lineY)
  mapM_ handlePin [1..40]
  mapM_ handlePin [49..56]

squareSize = 700
outputFile = "pin-diagram.png"

main :: IO ()
main = do
  let white = PixelRGBA8 255 255 255 255
      w = 2 * (30 + 4 * (blobLen + 10))
      h = 29 * rowHeight
      w' = max w squareSize
      h' = max h squareSize
      margin = (h' - h) / 2
      img = renderDrawing (round w') (round h') white $
            withTransformation (translate $ V2 (w' / 2) (rowHeight + margin)) drawing
      meta = M.singleton M.Software "https://github.com/ppelleti/diagram-pins"
  L.writeFile outputFile $ encodePngWithMetadata meta img
  putStrLn "Try processing the output file with:"
  putStrLn $
    "zopflipng -m --keepchunks=tEXt,zTXt,iTXt,gAMA " ++
    outputFile ++ " pin-diagram-z.png"
