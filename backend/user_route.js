const express = require('express')
const { jwtAuth } = require('../middleware/authentication')
const { createUserContainer } = require('../di/di')
const { celebrate, Joi } = require('celebrate')

const router = new express.Router()

const container = createUserContainer()
const userService = container.resolve('userService')

/**
 * PUBLIC
 * User login via email/password.
 *
 * @body { email, password }
 */
router.post('/login', (req, res, next) => {
    userService
        .login(req.body)
        .then(user => res.send(user))
        .catch(e => next(e))
})

/**
 * PUBLIC
 * New User signup via email/password.
 *
 * @body { email password }
 */
router.post(
    '/signup',
    celebrate({
        body: Joi.object().keys({
            email: Joi.string().email().required(),
            password: Joi.string().min(8).required(),
        }),
    }),
    (req, res, next) => {
        userService
            .signup(req.body)
            .then((user) => res.status(201).json(user))
            .catch((e) => next(e))
    }
)

/**
 * PUBLIC
 * New User verify via email.
 *
 *
 */
router.get('/verify/:email', (req, res, next) => {
    userService
        .verify(req.params.email)
        .then(text => res.send(text))
        .catch(e => next(e))
})

/**
 * PUBLIC
 * Continue with Google. Login or Signup via Google.
 *
 * @query idtoken
 */
router.post('/google', (req, res, next) => {
    userService
        .continueWithGoogle(req.query.idtoken)
        .then(user => {
            if(user.code === 200) res.send(user)
            else res.status(201).json(user)
        })
        .catch(e => next(e))
})

/**
 * PUBLIC
 * Continue with Facebook. Login or Signup via Facebook.
 *
 * @query accessToken
 */
router.post('/facebook', (req, res, next) => {
    userService
        .continueWithFacebook(req.query.accessToken)
        .then(user => {
            if(user.code === 200) res.send(user)
            else res.status(201).json(user)
        })
        .catch(e => next(e))
})

/**
 * PRIVATE
 * Delete user account.
 */
router.delete('/', jwtAuth, (req, res, next) => {
    userService
        .deleteAccount(req.user._id)
        .then(_ => res.sendStatus(204))
        .catch(e => next(e))
})

/**
 * PRIVATE
 * GET all Pet posts for the authorised User making the call.
 * Use the JWT token to get the User's ID.
 */
router.get('/pets', jwtAuth, (req, res, next) => {
    userService
        .getPetsForUser(req.user._id)
        .then(pets => res.json({ pets }))
        .catch(e => next(e))
})

router.post('/logout', jwtAuth, async (req, res) => {
    try {
        req.user.tokens = req.user.tokens.filter((token) => {
            return token.token !== req.token
        })

        await req.user.save()

        res.send()
    } catch(e) {
        res.status(500).send()
    }
})

module.exports = router