$:.unshift(File.dirname(__FILE__)+"/../lib")

require File.expand_path(File.dirname(__FILE__)+'/test_helper')

# Colour class unit test class.
class ImageNodeTest < Test::Unit::TestCase
   def setup
      @document = Document.new(Font.new(Font::ROMAN, 'Arial'))
   end
   def test_basics
      image = ImageNode.new(@document, fixture_file_path("bitmap1.bmp"), 1)

      assert(image.width  == 20)
      assert(image.height == 20)
      assert(image.x_scaling == nil)
      assert(image.y_scaling == nil)
      assert(image.top_crop == nil)
      assert(image.right_crop == nil)
      assert(image.left_crop == nil)
      assert(image.bottom_crop == nil)
   end

   def test_mutators
      image = ImageNode.new(@document, fixture_file_path("jpeg2.jpg"), 1)

      image.x_scaling = 75
      assert(image.x_scaling == 75)

      image.y_scaling = 60
      assert(image.y_scaling == 60)

      image.top_crop = 100
      assert(image.top_crop == 100)

      image.bottom_crop = 10
      assert(image.bottom_crop == 10)

      image.right_crop = 35
      assert(image.right_crop == 35)

      image.left_crop = 50
      assert(image.left_crop == 50)
   end

   def test_image_reading
      images = []
      images << ImageNode.new(@document, fixture_file_path('bitmap1.bmp'), 1)
      images << ImageNode.new(@document, fixture_file_path('bitmap2.bmp'), 2)
      images << ImageNode.new(@document, fixture_file_path('jpeg1.jpg'), 3)
      images << ImageNode.new(@document, fixture_file_path('jpeg2.jpg'), 4)
      images << ImageNode.new(@document, fixture_file_path('png1.png'), 5)
      images << ImageNode.new(@document, fixture_file_path('png2.png'), 6)

      assert(images[0].width == 20)
      assert(images[0].height == 20)
      assert(images[1].width == 123)
      assert(images[1].height == 456)
      assert(images[2].width == 20)
      assert(images[2].height == 20)
      assert(images[3].width == 123)
      assert(images[3].height == 456)
      assert(images[4].width == 20)
      assert(images[4].height == 20)
      assert(images[5].width == 123)
      assert(images[5].height == 456)
   end

   def test_rtf
      image = ImageNode.new(@document, fixture_file_path('png1.png'), 1)
      image.x_scaling   = 100
      image.y_scaling   = 75
      image.top_crop    = 10
      image.right_crop  = 15
      image.left_crop   = 20
      image.bottom_crop = 25
      rtf               = image.to_rtf

      assert(rtf == "{\\*\\shppict{\\pict\\picscalex100\\picscaley75"\
                    "\\piccropl20\\piccropr15\\piccropt10\\piccropb25"\
                    "\\picw20\\pich20\\bliptag1\\pngblip\n"\
                    "89504e470d0a1a0a0000000d494844520000001400000014080200000002eb8a5a00000001735247\n"\
                    "4200aece1ce90000000467414d410000b18f0bfc6105000000206348524d00007a26000080840000\n"\
                    "fa00000080e8000075300000ea6000003a98000017709cba513c000003dd49444154384f1d545b6c\n"\
                    "145518fee6cccccecc9e99d9b9ed76bbb3bdd8ae5b8144144413a335f141259228d60096b485aa2d\n"\
                    "b4686b634bb65b6d682244e2050d46239af0c88b181ff1c507f4411ec4447cf1f2808118d05ab1ed\n"\
                    "de778fff6cf2e73c9c33dfff7ddf7f1929052d015945890326d002cac0bfc05f30d624066b131d40\n"\
                    "0d5001016c020c68b6cf75e06ed84ff87d7b79728c1b33091c8d63c2c55ecf7a30c8596640c8f040\n"\
                    "3639ae741c55bba6b29de3e196d9befccb3db9e7b62104fa81a7adf428f75fe3c6b289a282e31ce3\n"\
                    "26df9dec330058c81fe9cdbde12697625e31482e66320b7eefab99ae17fa23455b81e74d678a270a\n"\
                    "aa7a1258014e4838c6947d5e97476013fd93416659958a40015864da02320b6e7632871e60277028\n"\
                    "61cf73bec2f01ef02ef03e50843c12f7badacc7d93b6bb0cbc05bcd38e37915ae1e1dc5dd802ec00\n"\
                    "46e2ca5c4c59024eb7c11f004b908765a397c01c3d633a9f6f4ba2378a027801d6a4037abe0f1875\n"\
                    "b5195b2fc878bbfd7a46370b317ec8f1a91cc4bc75bca383ca40b9c9d52938a7957025917925c400\n"\
                    "22f2215f7bd1d1a734b6a0c845595d34ac71591bf2dd148135dc3b92cfcde5f9acc716b856b4adb9\n"\
                    "78ea989b1e0b9103b2c0431c53db070e06f6b0a11f3613cf4aca81747a30e92608ac62d7fec7761c\n"\
                    "792a37f948f7f4aed4c4b67b6676660fe6b3cfe423e480a307887a461628d7fd6484b14ec0a6cbb4\n"\
                    "2fdb1e540f5a082384e923dd09c782a521134067a40bbdc98403108fdb0eea105d1a860446639585\n"\
                    "fa30f87e48fb802781c781c1a845d676a0138c29376ffc214445b42aa2d114cda668d51aa2561135\n"\
                    "2de882fe2877a675ed148f7d1206e77de723db3b13b70be9cc4bc003514d1a42b444fdd6ed1bf57a\n"\
                    "bd5a2764bd2a6a655107f381dd9a7e52c197b6fa43dafa09f8dae1df6bea05df3901ec895ab95eaa\n"\
                    "374493f0ad288b20dadbfffd1981e37d504754f59cc37f8db355e0baa5adc9b8095cb6ad8f81c330\n"\
                    "787abdd41482a25ebab3592b95230ba2541595762b860d7ed1f3fe614a15f85bb785ac3520ffe206\n"\
                    "5f01af13b341b2095cad6c44199aa2bcb146f896a0c5eb267090ba045ca56d8c99b493ab904ac0b5\n"\
                    "b87911381e6d2669aed43784a891e8f266ad49262217f469379346659c95f06d60ae1bb15585dd22\n"\
                    "d95cfbd1887d0eccc34870aa504b54ee6cac6e6e545b44de765eae34a8d30c4361f25cc6bb6280aa\n"\
                    "754595aec5d59f5d7ed9323e04a6c162ea6fd77f6f891a152c025150cd5af54aaddc19d2e0535767\n"\
                    "2dfd8b98f48d19ff2e99bcca70c9d02ee81acdfa3020a1bbbf87ce28a0ea9a153991e0fa3463343b\n"\
                    "830a9b05ce029fb5e3538004d3ee4ed04fe47f31ae584cdee40aed0000000049454e44ae426082"\
                    "\n}}")
   end

   def test_exceptions
      begin
         ImageNode.new(@document, 'lalala', 1)
         flunk("Created an ImageNode for a non-existent file.")
      rescue
      end

      begin
         ImageNode.new(@document, 'ImageNodeTest.rb', 1)
         flunk("Created an ImageNode from an unsupported file format.")
      rescue
      end
   end
end
