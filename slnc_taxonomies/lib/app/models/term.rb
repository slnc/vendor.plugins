class Term < ActiveRecord::Base
  named_scope :top_level, :conditions => 'id = root_id AND parent_id IS NULL'
  named_scope :in_taxonomy, lambda { |taxonomy| {:conditions => "taxonomy = '#{taxonomy}'"}}
  
  acts_as_rootable
  acts_as_tree :order => 'name'
  
  has_slug :name
  file_column :image
  
  before_save :check_references_to_ancestors
  before_save :copy_parent_attrs
  
  # VALIDATES siempre los últimos
  validates_format_of :slug, :with => /^[a-z0-9_.-]{0,50}$/
  validates_format_of :name, :with => /^.{1,100}$/
  validates_presence_of :taxonomy
  plain_text :name, :description
  validates_uniqueness_of :name, :scope => [:taxonomy, :parent_id]
  validates_uniqueness_of :slug, :scope => [:taxonomy, :parent_id]
  before_save :check_scope_if_toplevel
  
  before_save :check_taxonomy
  
  def self.taxonomies
    VALID_TAXONOMIES
  end
  
  def check_taxonomy
    if !self.class.taxonomies.include?(self.taxonomy)
      self.errors.add('term', "Taxonomía '#{self.taxonomy}' incorrecta. Taxonomías válidas: #{self.taxonomies.join(', ')}")
      false
    else
      true
    end
  end
  
  def check_scope_if_toplevel
    if self.new_record? && self.parent_id.nil?
      if Term.count(:conditions => ['parent_id IS NULL AND slug = ?', self.slug]) > 0
        self.errors.add('slug', 'Slug is already taken')
        false
      else
        true
      end
    elsif (!self.new_record?) && self.parent_id.nil?
      if Term.count(:conditions => ['id <> ? AND parent_id IS NULL AND slug = ?', self.id, self.slug]) > 0
        self.errors.add('slug', 'Slug is already taken')
        false
      else
        true
      end
    else
      true
    end
  end
  
  def copy_parent_attrs
    return true if self.id == self.root_id
    
    par = self.parent
    
    self.taxonomy = par.taxonomy if par.taxonomy
    true
  end
  
  
  def set_slug
    if self.slug.nil? || self.slug.to_s == ''
      self.slug = self.name.bare.downcase
      # TODO esto no comprueba si el slug está repetido
    end
    true
  end 
  
  def self.find_taxonomy(id, taxonomy)
    sql_tax = taxonomy.nil? ? 'IS NULL' : "= #{User.connection.quote(taxonomy)}"
    Term.find(:first, :conditions => ["id = ? AND taxonomy #{sql_tax}", id])
  end
  
  def self.find_taxonomy_by_code(code, taxonomy)
    # Solo para taxonomías toplevel
    Term.find(:first, :conditions => ['id = root_id AND code = ? AND taxonomy = ?', code, taxonomy])
  end
  
  
  # Devuelve los ids de los hijos de la categoría actual o de la categoría obj de forma recursiva incluido el id de obj
  def all_children_ids(opts={})
    cats = [self.id]
    conds = []
    conds << opts[:cond] if opts[:cond].to_s != ''
    conds << "taxonomy = #{User.connection.quote(opts[:taxonomy])}" if opts[:taxonomy]
    
    cond = ''
    cond = " AND #{conds.join(' AND ')}" if conds.size > 0
    
    
    if self.id == self.root_id then # shortcut
      db_query("SELECT id FROM terms WHERE root_id = #{self.id} AND id <> #{self.id} #{cond}").each { |dbc| cats<< dbc['id'].to_i }
    else # hay que ir preguntando categoría por categoría
      if conds.size > 0
        self.children.find(:all, :conditions => cond[4..-1]).each { |child| cats.concat(child.all_children_ids(opts)) }
      else
        self.children.find(:all).each { |child| cats.concat(child.all_children_ids(opts)) }
      end
    end
    cats.uniq
  end
  
  def self.taxonomy_from_class_name(cls_name)
    "#{ActiveSupport::Inflector::pluralize(cls_name)}Category"
  end
  
  
  def get_ancestors 
    # devuelve los ascendientes. en [0] el padre directo y en el último el root
    path = []
    parent = self.parent
    
    while parent do
      path<< parent
      parent = parent.parent
    end
    
    path
  end
  
  # TODO PERF
  def set_dummy
    @siblings ||= []
    Term.toplevel(:clan_id => nil).each do |t| @siblings<< t end
  end
  
  def add_sibling(sibling_term)
    raise "sibling_term must be a term but is a #{sibling_term.class.name}" unless sibling_term.class.name == 'Term'
    @siblings ||= []
    @siblings<< sibling_term
  end
  
  private
  def check_references_to_ancestors
    if !self.new_record?
      if slnc_changed?(:parent_id) then
        return false if self.parent_id == self.id # para evitar bucles infinitos
        self.root_id = parent_id.nil? ? self.id : self.class.find(parent_id).root_id
        self.class.find(:all, :conditions => "id IN (#{self.all_children_ids.join(',')})").each do |child|
          next if child.id == self.id
          child.root_id = self.root_id
          child.save
        end
      end
    end
    true
  end
end