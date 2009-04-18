require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module AttachmentFu
  class BasicAsset < ActiveRecord::Base
    is_faux_attachment
  end

  class QueuedAsset  < ActiveRecord::Base
    is_faux_attachment :queued => true
  end

  describe "AttachmentFu" do
    describe "pending creation" do
      before do
        @asset = BasicAsset.new(:content_type => 'application/x-ruby')
        @asset.set_temp_path __FILE__
      end

      it "has nil #full_path" do
        @asset.full_path.should be_nil
      end

      it "has nil #partitioned_path" do
        @asset.partitioned_path.should == nil
      end
    end

    describe "being processed" do
      before do
        @file = File.join(File.dirname(__FILE__), 'guinea_pig.rb')
        FileUtils.cp __FILE__, @file
      end

      after { @asset.destroy }

      it "attempts to process the attachment" do
        @asset = BasicAsset.new(:content_type => 'application/x-ruby')
        @asset.set_temp_path @file
        @asset.save!
        @asset.should_not be_queued
      end
      
      it "skips processing the queued attachment" do
        @asset = QueuedAsset.new(:content_type => 'application/x-ruby')
        @asset.set_temp_path @file
        @asset.save!
        @asset.should be_queued
      end
    end
    
    describe "being created" do
      before :all do
        @file = File.join(File.dirname(__FILE__), 'guinea_pig.rb')
        FileUtils.cp __FILE__, @file

        @asset = BasicAsset.new(:content_type => 'application/x-ruby')
        @asset.set_temp_path @file
        @asset.save!
      end

      after :all do
        @asset.destroy
      end

      it "stores asset in AttachmentFu root_path" do
        @asset.full_path.should == File.expand_path(File.join(AttachmentFu.root_path, "public/afu_spec_assets/#{@asset.partitioned_path * '/'}/guinea_pig.rb"))
      end

      it "creates full_path from record id and attachment_path" do
        @asset.full_path.should == File.expand_path(File.join(AttachmentFu.root_path, "public/afu_spec_assets/#{@asset.partitioned_path * '/'}/#{@asset.filename}"))
      end

      it "creates thumbnailed full_path from record id and attachment_path" do
        @asset.full_path(:foo).should == File.expand_path(File.join(AttachmentFu.root_path, "public/afu_spec_assets/#{@asset.partitioned_path * '/'}/guinea_pig_foo.rb"))
        begin
          @asset.filename = 'guinea_pig'
          @asset.full_path(:foo).should == File.expand_path(File.join(AttachmentFu.root_path, "public/afu_spec_assets/#{@asset.partitioned_path * '/'}/guinea_pig_foo"))
        ensure
          @asset.filename = 'guinea_pig.rb'
        end
      end

      it "creates public_path from record id and attachment_path" do
        @asset.public_path.should == "/afu_spec_assets/#{@asset.partitioned_path * '/'}/#{@asset.filename}"
      end

      it "creates thumbnailed public_path from record id and attachment_path" do
        @asset.public_path(:foo).should == "/afu_spec_assets/#{@asset.partitioned_path * '/'}/guinea_pig_foo.rb"
        begin
          @asset.filename = 'guinea_pig'
          @asset.public_path(:foo).should == "/afu_spec_assets/#{@asset.partitioned_path * '/'}/guinea_pig_foo"
        ensure
          @asset.filename = 'guinea_pig.rb'
        end
      end

      it "creates partitioned path from the record id" do
        @asset.partitioned_path.each { |piece| piece.should match(/^\d{4}$/) }
        @asset.partitioned_path.join.to_i.should == @asset.id
      end

      it "moves temp_path to new location" do
        File.exist?(@asset.full_path).should == true
      end

      it "removes old temp_path location" do
        File.exist?(@file).should == false
      end

      it "clears #temp_path" do
        @asset.temp_path.should be_nil
      end
    end

    describe "being renamed" do
      before :all do
        @file = File.join(File.dirname(__FILE__), 'guinea_pig.rb')
        FileUtils.cp __FILE__, @file

        @asset = BasicAsset.new(:content_type => 'application/x-ruby')
        @asset.set_temp_path @file
        @asset.save!
        @old_path = @asset.full_path
        @asset.filename = "hedgehog.rb"
        @asset.save!
      end

      after :all do
        @asset.destroy
      end

      it "removes traces of old filename" do
        File.exist?(@old_path).should == false
      end

      it "moves file contents to new filename" do
        File.exist?(@asset.full_path).should == true
        IO.read(@asset.full_path).should == IO.read(__FILE__)
      end
    end

    describe "being deleted" do
      before do
        @file = File.join(File.dirname(__FILE__), 'guinea_pig.rb')
        FileUtils.cp __FILE__, @file

        @asset = BasicAsset.new(:content_type => 'application/x-ruby')
        @asset.set_temp_path @file
        @asset.save!
        @dir   = File.dirname(@asset.full_path)
      end
      
      after do
        FileUtils.rm_rf AttachmentFu.root_path
      end
      
      it "removes the file" do
        @asset.destroy
        File.exist?(@asset.full_path).should == false
      end
      
      (1..4).each do |i|
        it "deletes empty path ##{i}" do
          @asset.destroy
          dir_to_check = @dir.split("/")[0..-i] * "/"
          fail "#{dir_to_check.inspect} still exists" if File.directory?(dir_to_check)
        end

        it "keeps non-empty path ##{i}" do
          dir_to_check = @dir.split("/")[0..-i] * "/"
          FileUtils.touch File.join(dir_to_check, 'savior')
          @asset.destroy
          fail "#{dir_to_check.inspect} is deleted" unless File.directory?(dir_to_check)
        end
      end
      
      it "keeps AttachmentFu.root_path" do
        @asset.destroy
        dir_to_check = @dir.split("/")[0..-5] * "/"
        fail "#{dir_to_check.inspect} is deleted" unless File.directory?(dir_to_check)
      end
    end
    
    describe "being uploaded" do
      before do
        @asset = BasicAsset.new
        @file  = __FILE__
        @file.stub!(:size).and_return(File.size(__FILE__))
        @file.stub!(:content_type).and_return("application/x-ruby")
        @file.stub!(:original_filename).and_return("/Users/rickybobby/shake_and_bake.rb")
        @file.stub!(:read).and_return { IO.read(__FILE__) }
      end
      
      describe "with temp file" do        
        it "sets temp_path as string path to file" do
          @asset.uploaded_data = @file
          @asset.temp_path.should == __FILE__
          @asset.temp_path.size.should == File.size(__FILE__)
        end

        it "sets content_type" do
          @asset.uploaded_data = @file
          @asset.content_type.should == @file.content_type
        end
      
        it "sets filename" do
          @asset.uploaded_data = @file
          @asset.filename.should == @file.original_filename
        end
        
        it "ignores nil value" do
          @asset.uploaded_data = nil
          @asset.content_type.should be_nil
        end
        
        it "ignores uploaded file with size=0" do
          @file.stub!(:size).and_return(0)
          @asset.uploaded_data = @file
          @asset.content_type.should be_nil
        end
      end
      
      describe "with IO" do
        before do
          @file.stub!(:rewind)
        end
        
        it "sets temp_path as Tempfile" do
          @asset.uploaded_data = @file
          @asset.temp_path.class.should == Tempfile
          @asset.temp_path.size.should == File.size(__FILE__)
        end

        it "sets content_type" do
          @asset.uploaded_data = @file
          @asset.content_type.should == @file.content_type
        end
      
        it "sets filename" do
          @asset.uploaded_data = @file
          @asset.filename.should == @file.original_filename
        end
        
        it "ignores nil value" do
          @asset.uploaded_data = nil
          @asset.content_type.should be_nil
        end
        
        it "ignores uploaded file with size=0" do
          @file.stub!(:size).and_return(0)
          @asset.uploaded_data = @file
          @asset.content_type.should be_nil
        end
      end
    end

    describe "setting temp_path" do
      describe "with a String" do
        before do
          @asset = BasicAsset.new
          @asset.set_temp_path __FILE__
        end

        it "guesses filename" do
          @asset.filename.should == File.basename(__FILE__)
        end
        
        it "sets #size" do
          @asset.size.should == File.size(__FILE__)
        end
      end

      describe "with a Pathname" do
        before  do
          @asset = BasicAsset.new
          @asset.set_temp_path Pathname.new(__FILE__)
        end

        it "guesses filename" do
          @asset.filename.should == File.basename(__FILE__)
        end
        
        it "sets #size" do
          @asset.size.should == File.size(__FILE__)
        end
      end
      
      describe "with a Tempfile" do
        before do
          @tmp = Tempfile.new File.basename(__FILE__)
          @tmp.write IO.read(__FILE__)
          @asset = BasicAsset.new
          @asset.set_temp_path @tmp
        end

        it "guesses filename" do
          name, ext = File.basename(__FILE__).split(".")
          @asset.filename.should include(name) # tempfile adds extra characters to the end
          @asset.filename.should match(/\.rb$/)
        end
        
        it "sets #size" do
          @asset.size.should == File.size(__FILE__)
        end
      end
    end
    
    describe "being subclassed" do
      before do
        @sub = Class.new(BasicAsset)
      end

      it "inherits superclass #attachment_path" do
        @sub.attachment_path.should == BasicAsset.attachment_path
      end

      it "inherits superclass #attachment_path after explicit #is_attachment call" do
        @sub.is_attachment
        @sub.attachment_path.should == BasicAsset.attachment_path
      end
      
      it "overwrites superclass #attachment_path with :path" do
        @sub.is_attachment :path => 'foobar'
        @sub.attachment_path.should_not == BasicAsset.attachment_path
        @sub.attachment_path.should == 'foobar'
      end
    end

    before :all do
      BasicAsset.setup_spec_env
    end
    
    after :all do
      BasicAsset.drop_spec_env
      FileUtils.rm_rf AttachmentFu.root_path
    end
  end
end