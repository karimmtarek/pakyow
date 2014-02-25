class Contact
  attr_accessor :full_name, :email

  def initialize(full_name, email)
    @full_name = full_name
    @email = email
  end

  def [](key)
    send(key)
  end
end

describe "binding data to" do
  before do
    @views = {}

    @views[:many] = create_view_from_string(<<-D)
    <div class="contact" data-scope="contact">
      <span data-prop="full_name">John Doe</span>
      <a data-prop="email">john@example.com</a>
    </div>
    <div class="contact" data-scope="contact">
      <span data-prop="full_name">John Doe</span>
      <a data-prop="email">john@example.com</a>
    </div>
    <div class="contact" data-scope="contact">
      <span data-prop="full_name">John Doe</span>
      <a data-prop="email">john@example.com</a>
    </div>
    D

    @views[:single] = create_view_from_string(<<-D)
    <div class="contact" data-scope="contact">
      <span data-prop="full_name">John Doe</span>
      <a data-prop="email">john@example.com</a>
    </div>
    D

    @views[:unscoped] = create_view_from_string(<<-D)
    <span class="foo" data-prop="foo"></span>
    D
  end

  describe View do
    before do
      @view = View.new
    end

    describe '#with' do
      it "yields context" do
        @view.with { |ctx|
          assert_same @view, ctx
        }
      end

      it "calls block in context of view" do
        ctx = nil
        @view.with {
          ctx = self
        }

        assert_same @view, ctx
      end
    end

    describe '#for' do
      before do
        @data = [{}]
      end

      it "yields each view/datum pair" do
        @view.for(@data) do |ctx, datum|
          assert_same @view, ctx
          assert_same @data[0], datum
        end
      end

      it "calls block in context of view, yielding datum" do
        ctx = nil
        ctx_datum = nil
        @view.for(@data) do |datum|
          ctx = self
          ctx_datum = datum
        end

        assert_same @view, ctx
        assert_same @data[0], ctx_datum
      end

      it "stops when no more views" do
        count = 0
        @view.for(3.times.to_a) do |datum|
          count += 1
        end

        assert count == 1
      end

      it "handles non-array data" do
        data = {}
        @view.for(data) do |ctx, datum|
          assert_same data, datum
        end
      end
    end

    describe '#for_with_index' do
      before do
        @data = [{}]
      end

      it "yields each view/datum pair" do
        @view.for_with_index(@data) do |ctx, datum, i|
          assert_same @view, ctx
          assert_same @data[0], datum
          assert i == 0
        end
      end

      it "calls block in context of view, yielding datum" do
        ctx = nil
        ctx_datum = nil
        ctx_i = nil
        @view.for_with_index(@data) do |datum, i|
          ctx = self
          ctx_datum = datum
          ctx_i = i
        end

        assert_same @view, ctx
        assert_same @data[0], ctx_datum
        assert ctx_i == 0
      end
    end

    describe '#match' do
      before do
        @data = [{}, {}, {}]
        @view = view(:single)
        @view_to_match = @view.scope(:contact)[0]
        @views = @view_to_match.match(@data)
      end

      it "creates a collection of views" do
        assert @views.length == @data.length
      end

      it "sets up each created view" do
        @views.each do |view|
          assert_equal @view_to_match.bindings, view.bindings
          assert_same @view_to_match.scoped_as, view.scoped_as
          assert_same @view_to_match.context, view.context
          assert_same @view_to_match.composer, view.composer
        end
      end

      it "removes the original view" do
        @view.bindings(true)
        assert @view.scope(:contact).length == @data.length
      end
    end

    describe '#repeat' do
      it "matches, then calls for" do
        view = RepeatingTestView.new("")
        view.repeat([{}, {}, {}]) {}

        assert view.calls.include?(:match)
        assert view.calls.include?(:for)
      end
    end

    describe '#repeat_with_index' do
      it "matches, then calls for_with_index" do
        view = RepeatingTestView.new("")
        view.repeat_with_index([{}, {}, {}]) {}

        assert view.calls.include?(:match)
        assert view.calls.include?(:for_with_index)
      end
    end

    describe '#bind' do
      it "binds to unscoped props" do
        data = { :foo => 'bar' }
        view = view(:unscoped)
        view.bind(data)

        assert_equal data[:foo], view.doc.css('.foo').first.content
      end

      it "binds a hash" do
        data = {:full_name => "Jugyo Kohno", :email => "jugyo@example.com"}
        view = view(:single)
        view.scope(:contact)[0].bind(data)

        assert_equal data[:full_name], view.doc.css('.contact span').first.content
        assert_equal data[:email],     view.doc.css('.contact a').first.content
      end

      it "binds an object" do
        data = Contact.new("Jugyo Kohno", "jugyo@example.com")
        view = view(:single)
        view.scope(:contact)[0].bind(data)

        assert_equal data[:full_name], view.doc.css('.contact span').first.content
        assert_equal data[:email],     view.doc.css('.contact a').first.content
      end
    end

    describe '#apply' do
      it "matches, then binds" do
        view = RepeatingTestView.new("")
        view.apply([{}, {}, {}]) {}

        assert view.calls.include?(:match)
        assert view.calls.include?(:bind)
      end
    end
  end

  describe ViewCollection do
    describe '#with' do
    end

    describe '#for' do
    end

    describe '#match' do
    end

    describe '#repeat' do
    end

    describe '#bind' do
      it "binds a hash" do
        data = {:full_name => "Jugyo Kohno", :email => "jugyo@example.com"}
        view = view(:single)
        view.scope(:contact).bind(data)

        assert_equal data[:full_name], view.doc.css('.contact span').first.content
        assert_equal data[:email],     view.doc.css('.contact a').first.content
      end

      it "binds an object" do
        data = Contact.new("Jugyo Kohno", "jugyo@example.com")
        view = view(:single)
        view.scope(:contact).bind(data)

        assert_equal data[:full_name], view.doc.css('.contact span').first.content
        assert_equal data[:email],     view.doc.css('.contact a').first.content
      end

      it "binds data across views" do
        skip
      end

      it "stops binding when no more data" do
        skip
      end

      it "stops binding when no more views" do
        skip
      end
    end

    describe '#apply' do
    end
  end

  private

  def create_view_from_string(string)
    doc = Nokogiri::HTML::Document.parse(string)
    View.from_doc(doc.root)
  end

  def view(type)
    @views.fetch(type)
  end
end

class RepeatingTestView < Pakyow::Presenter::View
  attr_reader :calls

  def initialize(*args)
    @calls = []
    super
  end

  def repeat(*args, &block)
    @calls << :repeat
    super
  end

  def repeat_with_index(*args, &block)
    @calls << :repeat_with_index
    super
  end

  def match(*args, &block)
    @calls << :match
    super
    self
  end

  def for(*args, &block)
    @calls << :for
    super
  end

  def for_with_index(*args, &block)
    @calls << :for_with_index
    super
  end

  def bind(*args, &block)
    @calls << :bind
    super
  end
end
