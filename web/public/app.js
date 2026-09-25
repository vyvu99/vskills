const root = document.getElementById('root');
let template = null;
let answers = {};

function el(tag, attrs = {}, children = []) {
  const node = document.createElement(tag);
  for (const [key, value] of Object.entries(attrs)) {
    if (key === 'class') node.className = value;
    else if (key.startsWith('on')) node.addEventListener(key.slice(2), value);
    else node.setAttribute(key, value);
  }
  for (const child of [].concat(children)) {
    node.append(child instanceof Node ? child : document.createTextNode(child));
  }
  return node;
}

function renderSelectField(field) {
  const fieldset = el('fieldset', {}, [el('legend', {}, field.label)]);
  if (field.description) fieldset.append(el('p', { class: 'field-description' }, field.description));

  for (const option of field.options) {
    const radio = el('input', {
      type: 'radio',
      name: field.id,
      value: option.value,
      onchange: () => { answers[field.id] = option.value; },
    });
    if (answers[field.id] === option.value) radio.checked = true;

    const row = el('label', { class: 'option-row' }, [radio]);
    if (option.renderHint === 'swatch') {
      row.append(el('span', { class: 'swatch', style: `background:${option.value}` }));
    }
    const labelSpan = el('span', {}, option.label);
    if (option.renderHint === 'font-sample') labelSpan.style.fontFamily = option.value;
    row.append(labelSpan);
    fieldset.append(row);
  }
  return fieldset;
}

function renderTextField(field) {
  const fieldset = el('fieldset', {}, [el('legend', {}, field.label)]);
  if (field.description) fieldset.append(el('p', { class: 'field-description' }, field.description));
  const textarea = el('textarea', {
    rows: 4,
    placeholder: field.placeholder || '',
    oninput: (e) => { answers[field.id] = e.target.value; },
  });
  textarea.value = answers[field.id] || '';
  fieldset.append(textarea);
  return fieldset;
}

function renderDiffReviewListField(field) {
  const fieldset = el('fieldset', {}, [el('legend', {}, field.label)]);
  const decisions = answers[field.id] || field.items.map((item) => ({ id: item.id, action: item.default || 'apply' }));
  answers[field.id] = decisions;

  for (const item of field.items) {
    const decision = decisions.find((d) => d.id === item.id);
    const actionsRow = el('div', { class: 'diff-actions' });
    for (const action of item.actions) {
      const radio = el('input', {
        type: 'radio',
        name: `${field.id}-${item.id}`,
        onchange: () => { decision.action = action; },
      });
      if (decision.action === action) radio.checked = true;
      actionsRow.append(el('label', {}, [radio, ` ${action}`]));
    }
    if (item.allowFreeText) {
      const freeText = el('input', {
        type: 'text',
        placeholder: 'Override...',
        style: 'flex:1',
        oninput: (e) => { decision.freeText = e.target.value; },
      });
      freeText.value = decision.freeText || '';
      actionsRow.append(freeText);
    }

    fieldset.append(
      el('div', { class: 'diff-item' }, [
        el('div', { class: 'diff-grid' }, [
          el('div', { class: 'diff-block diff-before' }, item.before),
          el('div', { class: 'diff-block diff-after' }, item.after),
        ]),
        actionsRow,
      ]),
    );
  }
  return fieldset;
}

const FIELD_RENDERERS = {
  select: renderSelectField,
  text: renderTextField,
  'diff-review-list': renderDiffReviewListField,
};

function render() {
  root.replaceChildren();
  if (!template) {
    root.append(el('p', {}, 'Waiting for the next step...'));
    return;
  }

  root.append(el('h1', {}, template.title));
  for (const field of template.fields) {
    const renderer = FIELD_RENDERERS[field.type];
    if (renderer) root.append(renderer(field));
  }
  root.append(el('button', { onclick: submit }, 'Submit'));
}

async function submit() {
  const button = root.querySelector('button');
  button.disabled = true;
  button.textContent = 'Submitting...';
  await fetch('/api/answer', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(answers),
  });
  template = null;
  answers = {};
  render();
}

async function poll() {
  if (!template) {
    const current = await (await fetch('/api/current')).json();
    if (current) {
      template = current;
      render();
    }
  }
  setTimeout(poll, 1000);
}

render();
poll();
