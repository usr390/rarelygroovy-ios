import { expect, browser, $ } from '@wdio/globals'

describe('Rarelygroovy app', () => {
  it('should open home screen', async () => {
    const homeTitle = await $('~calendar') // using accessibility id
    await expect(homeTitle).toBeDisplayed()
  })
})


